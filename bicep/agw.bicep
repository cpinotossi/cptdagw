targetScope='resourceGroup'

var parameters = json(loadTextContent('../parameters.json'))
var servercertificatefrontend = loadFileAsBase64('../openssl/srv.pfx')
var cacertificatebackend = loadFileAsBase64('../openssl/ca.crt')

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: parameters.prefix
}

resource fwp1 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2021-03-01' = {
  name: parameters.prefix
  location:parameters.location
  properties: {
    policySettings: {
      state:'Enabled'
      mode:'Prevention'
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
    customRules:[
      {
        name:'customrule1'
        priority:5
        ruleType:'MatchRule'
        action:'Block'
        matchConditions:[
          {
            matchVariables:[
              {
                variableName:'QueryString'
              }
            ]
            operator:'Contains'
            transforms:[
              'Lowercase'
            ]
            matchValues:[
              'evil'
            ]
          }
        ]
      }
    ]
  }
}

resource pubip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: parameters.prefix
  location: parameters.location
  sku:{
    tier:'Regional'
    name:'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings:{
      domainNameLabel:parameters.prefix
    }
  }
}

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: parameters.prefix
  location: parameters.location
}

resource agw 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: parameters.prefix
  location: parameters.location
  identity: {
    type:'UserAssigned'
    userAssignedIdentities:{
      '${umid.id}':{}
    }
  }
  properties:{
    sku:{
      capacity:1
      tier:'WAF_v2'
      name: 'WAF_v2'
    }
    sslCertificates: [
      {
        name: parameters.cnCertificateFrontend
        properties:{
          data: servercertificatefrontend
          password:'test123!'
        }
      }
    ]
    trustedRootCertificates: [
      {
        name:parameters.cnCABackend
        properties: {
          data: cacertificatebackend
        }
      }
    ]
    gatewayIPConfigurations:[
      {
        name:parameters.prefix
        properties:{
          subnet:{
            id: '${vnet.id}/subnets/${parameters.prefix}agw'
          }
        }
      }
    ]
    frontendIPConfigurations:[
      {
        name:'frontendIPConfigurationPublic'
        properties:{
          publicIPAddress:{
            id:pubip.id
          }
        }
      }
      {
        name: 'frontendIPConfigurationPrivate'
        properties: {
          privateIPAddress: '10.0.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnet.id}/subnets/${parameters.prefix}agw'
          }
        }
      }
    ]
    frontendPorts:[
      {
        name: 'frontendport80'
        properties: {
          port: 80
        }
      }
      {
        name: 'frontendport443'
        properties: {
          port: 443
        }
      }
    ]
    httpListeners:[
      {
        name:'httplistener1'
        properties:{
          protocol:'Http'
          requireServerNameIndication:false
          frontendIPConfiguration:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/frontendIPConfigurations/frontendIPConfigurationPrivate'
          }
          frontendPort:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/frontendPorts/frontendport80'
          }
        }
      }
      {
        name:'httplistener2'
        properties:{
          protocol:'Https'
          requireServerNameIndication:true
          frontendIPConfiguration:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/frontendIPConfigurations/frontendIPConfigurationPrivate'
          }
          frontendPort:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/frontendPorts/frontendport443'
          }
          sslCertificate: {
            id: '${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/sslCertificates/${parameters.cnCertificateFrontend}'
          }
          hostNames: [
            '${parameters.cnCertificateFrontend}'
            '${parameters.cnCABackend}'
          ]
          firewallPolicy:{
            id:fwp1.id
          }
        }
      }
    ]
    backendAddressPools:[
      {
        name:'backendaddresspool1'
        properties:{
          backendAddresses:[
            {
              fqdn:'${parameters.prefix}.blob.core.windows.net'
            }
          ]
        }
      }
      {
        name:'backendaddresspool2'
        properties:{
          backendAddresses:[
            {
              ipAddress:'10.0.2.4'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection:[
      {
        name:'backendhttpsetting1'
        properties:{
          port:443
          protocol:'Https'
          pickHostNameFromBackendAddress:true
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/probes/healthprobe1'
          }
        }
      }
      {
        name:'backendhttpsetting2'
        properties:{
          port:8080
          protocol:'Https'
          pickHostNameFromBackendAddress:false
          hostName:'${parameters.cnCertificateFrontend}'
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/probes/healthprobe2'
          }
          trustedRootCertificates:[
            {
              id: '${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/trustedRootCertificates/${parameters.cnCABackend}'
            }
          ]
        }
      }
    ]
    requestRoutingRules:[
      {
        name:'requestroutingrule1'
        properties:{
          ruleType:'Basic'
          httpListener:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/httpListeners/httplistener1'
          }
          backendAddressPool:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/backendAddressPools/backendaddresspool1'
          }
          backendHttpSettings:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/backendHttpSettingsCollection/backendhttpSetting1'
          }
        }
      }
      {
        name:'requestroutingrule2'
        properties:{
          ruleType:'Basic'
          httpListener:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/httpListeners/httplistener2'
          }
          backendAddressPool:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/backendAddressPools/backendaddresspool2'
          }
          backendHttpSettings:{
            id:'${resourceId('Microsoft.Network/applicationGateways', parameters.prefix)}/backendHttpSettingsCollection/backendhttpSetting2'
          }
        }
      }
    ]
    probes: [
      {
        name: 'healthprobe1'
        properties: {
          protocol: 'Https'
          path: '/${parameters.prefix}/test.txt'
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
      {
        name: 'healthprobe2'
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          host:'${parameters.cnCertificateFrontend}'
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
  }
}


