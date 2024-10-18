param applicationGateways_cptdazappgw_name string = 'cptdazappgw'
param virtualNetworks_cptdazappgw_externalid string = '/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/cptdazappgw/providers/Microsoft.Network/virtualNetworks/cptdazappgw'
param publicIPAddresses_cptdazappgw_externalid string = '/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/cptdazappgw/providers/Microsoft.Network/publicIPAddresses/cptdazappgw'

resource applicationGateways_cptdazappgw_name_resource 'Microsoft.Network/applicationGateways@2024-01-01' = {
  name: applicationGateways_cptdazappgw_name
  location: 'northeurope'
  zones: [
    '1'
  ]
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      family: 'Generation_1'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        id: '${applicationGateways_cptdazappgw_name_resource.id}/gatewayIPConfigurations/appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${virtualNetworks_cptdazappgw_externalid}/subnets/agwsubnet'
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: applicationGateways_cptdazappgw_name
        id: '${applicationGateways_cptdazappgw_name_resource.id}/sslCertificates/${applicationGateways_cptdazappgw_name}'
        properties: {}
      }
    ]
    trustedRootCertificates: [
      {
        name: '${applicationGateways_cptdazappgw_name}e3994cee-89c6-4515-9cd0-b203f7a1007_'
        id: '${applicationGateways_cptdazappgw_name_resource.id}/trustedRootCertificates/${applicationGateways_cptdazappgw_name}e3994cee-89c6-4515-9cd0-b203f7a1007_'
        properties: {
          data: 'MIIBvTCCAWSgAwIBAgIUZKYlVzdNfkXjz6F0y2wdoYDN49MwCgYIKoZIzj0EAwIwGDEWMBQGA1UEAwwNY3B0ZGV2LmNvbSBDQTAeFw0yNDEwMTcxOTM5NTJaFw0yNTEwMTcxOTM5NTJaMBgxFjAUBgNVBAMMDWNwdGRldi5jb20gQ0EwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASUH22gUeAS1ovqouqvQ/k/PmaJqdzxatdfHnMx3PqiQXUhvg405I9u5fmxMr2XBKnNFA5c+Wqr0ncP7g+DP2Ymo4GLMIGIMB0GA1UdDgQWBBQ04cuk8SYeoxW2eVOAo86TUgdJvjBTBgNVHSMETDBKgBQ04cuk8SYeoxW2eVOAo86TUgdJvqEcpBowGDEWMBQGA1UEAwwNY3B0ZGV2LmNvbSBDQYIUZKYlVzdNfkXjz6F0y2wdoYDN49MwEgYDVR0TAQH/BAgwBgEB/wIBADAKBggqhkjOPQQDAgNHADBEAiAQcijKJQOwswWwxH4D2HkCAtH7zWhPIjmr2DUtXxNgSwIgZk5b3gIwxkizZQEE3foG5MThdp0DIZ/wGr0Y9CfBFdQ='
        }
      }
    ]
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIpIPv4'
        id: '${applicationGateways_cptdazappgw_name_resource.id}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_cptdazappgw_externalid
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        id: '${applicationGateways_cptdazappgw_name_resource.id}/frontendPorts/port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: applicationGateways_cptdazappgw_name
        id: '${applicationGateways_cptdazappgw_name_resource.id}/backendAddressPools/${applicationGateways_cptdazappgw_name}'
        properties: {
          backendAddresses: []
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: applicationGateways_cptdazappgw_name
        id: '${applicationGateways_cptdazappgw_name_resource.id}/backendHttpSettingsCollection/${applicationGateways_cptdazappgw_name}'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          hostName: 'red.cptdev.com'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: '${applicationGateways_cptdazappgw_name_resource.id}/probes/${applicationGateways_cptdazappgw_name}'
          }
          trustedRootCertificates: [
            {
              id: '${applicationGateways_cptdazappgw_name_resource.id}/trustedRootCertificates/${applicationGateways_cptdazappgw_name}e3994cee-89c6-4515-9cd0-b203f7a1007_'
            }
          ]
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: applicationGateways_cptdazappgw_name
        id: '${applicationGateways_cptdazappgw_name_resource.id}/httpListeners/${applicationGateways_cptdazappgw_name}'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGateways_cptdazappgw_name_resource.id}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
          }
          frontendPort: {
            id: '${applicationGateways_cptdazappgw_name_resource.id}/frontendPorts/port_443'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${applicationGateways_cptdazappgw_name_resource.id}/sslCertificates/${applicationGateways_cptdazappgw_name}'
          }
          hostNames: [
            'www.cptdev.com'
            'red.cptdev.com'
          ]
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
    ]
    listeners: []
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: applicationGateways_cptdazappgw_name
        id: '${applicationGateways_cptdazappgw_name_resource.id}/requestRoutingRules/${applicationGateways_cptdazappgw_name}'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: '${applicationGateways_cptdazappgw_name_resource.id}/httpListeners/${applicationGateways_cptdazappgw_name}'
          }
          backendAddressPool: {
            id: '${applicationGateways_cptdazappgw_name_resource.id}/backendAddressPools/${applicationGateways_cptdazappgw_name}'
          }
          backendHttpSettings: {
            id: '${applicationGateways_cptdazappgw_name_resource.id}/backendHttpSettingsCollection/${applicationGateways_cptdazappgw_name}'
          }
          rewriteRuleSet: {
            id: '${applicationGateways_cptdazappgw_name_resource.id}/rewriteRuleSets/${applicationGateways_cptdazappgw_name}'
          }
        }
      }
    ]
    routingRules: []
    probes: [
      {
        name: applicationGateways_cptdazappgw_name
        id: '${applicationGateways_cptdazappgw_name_resource.id}/probes/${applicationGateways_cptdazappgw_name}'
        properties: {
          protocol: 'Https'
          path: '/redirect'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
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
        name: applicationGateways_cptdazappgw_name
        id: '${applicationGateways_cptdazappgw_name_resource.id}/rewriteRuleSets/${applicationGateways_cptdazappgw_name}'
        properties: {
          rewriteRules: [
            {
              ruleSequence: 100
              conditions: [
                {
                  variable: 'http_resp_Location'
                  pattern: '(.*)(redirect_uri=https%3A%2F%2F).*\\.azurewebsites\\.net(.*)$'
                  ignoreCase: true
                  negate: false
                }
              ]
              name: applicationGateways_cptdazappgw_name
              actionSet: {
                requestHeaderConfigurations: []
                responseHeaderConfigurations: [
                  {
                    headerName: 'Location'
                    headerValue: '{http_resp_Location_1}{http_resp_Location_2}www.cptdev.com{http_resp_Location_3}'
                  }
                ]
              }
            }
          ]
        }
      }
    ]
    redirectConfigurations: []
    privateLinkConfigurations: []
    enableHttp2: false
  }
}
