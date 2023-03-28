targetScope = 'resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'
param certpassword string = 'dummy'
param cnCertificateFrontend string = 'dummy'
param cnCABackend string = 'dummy'
param frontendip string
param backendip string

// var parameters = json(loadTextContent('../parameters.json'))
var servercertificatefrontend = loadFileAsBase64('../openssl/srv.pfx') //CN = test.cptdagw.org
var cacertificatebackend = loadFileAsBase64('../openssl/ca.crt') //CN = cptdagw.org
var clientcertificatefrontend = loadFileAsBase64('../openssl/ca.crt')

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: prefix
}

resource sab 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: prefix
}

resource fwp1 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2021-03-01' = {
  name: prefix
  location: location
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: false
      maxRequestBodySizeInKb: 128
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: []
        }
      ]
    }
    customRules: [
      {
        name: 'customrule1'
        priority: 5
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'QueryString'
              }
            ]
            operator: 'Contains'
            transforms: [
              'Lowercase'
            ]
            matchValues: [
              'evil'
            ]
          }
        ]
      }
    ]
  }
}

resource pubip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}agw'
  location: location
  sku: {
    tier: 'Regional'
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: prefix
    }
  }
}

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: prefix
  location: location
}

resource agw 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: prefix
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umid.id}': {}
    }
  }
  properties: {
    sku: {
      capacity: 1
      tier: 'WAF_v2'
      name: 'WAF_v2'
    }
    sslCertificates: [
      {
        name: cnCertificateFrontend // test.cptdagw.org
        properties: {
          data: servercertificatefrontend //PEM: CN = test.cptdagw.org
          password: certpassword
        }
      }
    ]
    trustedRootCertificates: [
      {
        name: cnCABackend //cptdagw.org
        properties: {
          data: cacertificatebackend // PEM: CN = cptdagw.org
        }
      }
    ]
    trustedClientCertificates: [
      {
        name: prefix
        properties: {
          data: clientcertificatefrontend
        }
      }
    ]
    sslProfiles: [
      {
        name: prefix
        properties: {
          clientAuthConfiguration: {
            verifyClientCertIssuerDN: false
          }
          trustedClientCertificates: [
            {
              id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/trustedClientCertificates/${prefix}'
            }
          ]
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: prefix
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${prefix}agw'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIPConfigurationPublic'
        properties: {
          publicIPAddress: {
            id: pubip.id
          }
        }
      }
      {
        name: 'frontendIPConfigurationPrivate'
        properties: {
          privateIPAddress: frontendip
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnet.id}/subnets/${prefix}agw'
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontendportTls'
        properties: {
          port: 443
        }
      }
      {
        name: 'frontendportHttp'
        properties: {
          port: 80
        }
      }
    ]
    httpListeners: [
      {
        name: 'httplistenerTls'
        properties: {
          protocol: 'Https'
          requireServerNameIndication: true
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendIPConfigurations/frontendIPConfigurationPrivate'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendPorts/frontendportTls'
          }
          sslCertificate: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/sslCertificates/${cnCertificateFrontend}'
          }
          sslProfile: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/sslProfiles/${prefix}'
          }
          hostNames: [
            cnCertificateFrontend // test.cptdagw.org
            cnCABackend // cptdagw.org just for testing multi hostname support via SNI.
          ]
          firewallPolicy: {
            id: fwp1.id
          }
        }
      }
      {
        name: 'httplistenerHttp'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendIPConfigurations/frontendIPConfigurationPrivate'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendPorts/frontendportHttp'
          }
          hostNames: [
            cnCertificateFrontend
            cnCABackend
          ]
          firewallPolicy: {
            id: fwp1.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendaddresspool'
        properties: {
          backendAddresses: [
            {
              ipAddress: backendip
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backendhttpsettingTls'
        properties: {
          port: 4040
          protocol: 'Https'
          pickHostNameFromBackendAddress: false
          hostName: cnCertificateFrontend
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/probes/healthprobeTls'
          }
          trustedRootCertificates: [
            {
              id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/trustedRootCertificates/${cnCABackend}'
            }
          ]
        }
      }
      {
        name: 'backendhttpsettingHttp'
        properties: {
          port: 8080
          protocol: 'Http'
          pickHostNameFromBackendAddress: false
          hostName: cnCertificateFrontend
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/probes/healthprobeHttp'
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'requestroutingruleTls'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/httpListeners/httplistenerTls'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendAddressPools/backendaddresspool'
          }
          backendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendHttpSettingsCollection/backendhttpSettingTls'
          }
          rewriteRuleSet: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/rewriteRuleSets/${prefix}'
          }
        }
      }
      {
        name: 'requestroutingruleHttp'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/httpListeners/httplistenerHttp'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendAddressPools/backendaddresspool'
          }
          backendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendHttpSettingsCollection/backendhttpSettingHttp'
          }
        }
      }
    ]
    probes: [
      {
        name: 'healthprobeTls'
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          host: cnCertificateFrontend
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'healthprobeHttp'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          host: cnCertificateFrontend
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]

    rewriteRuleSets: [
      {
        name: prefix
        properties: {
          rewriteRules: [
            {
              ruleSequence: 100
              conditions: []
              name: '${prefix}clientcert'
              actionSet: {
                requestHeaderConfigurations: [
                  {
                    headerName: 'X-PEM'
                    headerValue: '{var_client_certificate}'
                  }
                ]
                responseHeaderConfigurations: []
              }
            }
          ]
        }
      }
    ]
  }
}
