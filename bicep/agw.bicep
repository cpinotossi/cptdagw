targetScope = 'resourceGroup'

param prefix string
param location string
param hostname string
param frontendip string
param backendhttpport int


resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: prefix
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
      tier: 'Standard_v2'
      name: 'Standard_v2'
    }
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
        name: 'frontendportHttp'
        properties: {
          port: 8000
        }
      }
      {
        name: 'frontendportHttp80'
        properties: {
          port: 80
        }
      }
    ]
    httpListeners: [
      {
        name: 'httplistenerHttp'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendIPConfigurations/frontendIPConfigurationPublic'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendPorts/frontendportHttp'
          }
          hostName: ''
        }
      }
      {
        name: 'green'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendIPConfigurations/frontendIPConfigurationPublic'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendPorts/frontendportHttp'
          }
          hostName: 'green.${prefix}.org'
          requireServerNameIndication:true
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendaddresspool'
        properties: {
          backendAddresses: [

          ]
        }
      }
      {
        name: 'green'
        properties: {
          backendAddresses: [

          ]
        }
      }
      {
        name: 'blue'
        properties: {
          backendAddresses: [

          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backendhttpsettingHttp'
        properties: {
          port: backendhttpport
          connectionDraining:{
            drainTimeoutInSec: 3600 
            enabled: true
          }
          protocol: 'Http'
          pickHostNameFromBackendAddress: false
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/probes/healthprobeHttp'
          }
        }
      }
      {
        name: 'green'
        properties: {
          port: backendhttpport
          connectionDraining:{
            drainTimeoutInSec: 3600 
            enabled: true
          }
          protocol: 'Http'
          pickHostNameFromBackendAddress: false
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/probes/green'
          }
        }
      }
      {
        name: 'blue'
        properties: {
          port: backendhttpport
          connectionDraining:{
            drainTimeoutInSec: 3600 
            enabled: true
          }
          protocol: 'Http'
          pickHostNameFromBackendAddress: false
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/probes/blue'
          }
        }
      }
    ]
    requestRoutingRules: [
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
      {
        name: 'blue'
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 2002
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/httpListeners/blue'
          }
          urlPathMap:{
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/urlPathMaps/blue'
          }
        }
      }
    ]
    urlPathMaps:[
      {
        name:'blue'
        properties:{
          defaultBackendAddressPool:{
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendAddressPools/blue'
          }
          defaultBackendHttpSettings:{
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendHttpSettingsCollection/blue'
          }
          pathRules:[
            {
              name:'green'
              properties:{
                paths:[
                  '/green/*' 
                ]
                backendAddressPool:{
                  id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendAddressPools/green'
                }
                backendHttpSettings:{
                  id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendHttpSettingsCollection/green'
                }
              }
            }
          ]
        }
      }
      {
        name:'green'
        properties:{
          defaultBackendAddressPool:{
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendAddressPools/green'
          }
          defaultBackendHttpSettings:{
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendHttpSettingsCollection/green'
          }
          pathRules:[
            {
              name:'blue'
              properties:{
                paths:[
                  '/blue/*' 
                ]
                backendAddressPool:{
                  id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendAddressPools/blue'
                }
                backendHttpSettings:{
                  id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendHttpSettingsCollection/blue'
                }
              }
            }
          ]
        }
      }
    ]
    probes: [
      {
        name: 'healthprobeHttp'
        properties: {
          protocol: 'Http'
          path: '/index.html'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          host: hostname
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'green'
        properties: {
          protocol: 'Http'
          path: '/green'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          // host: hostname
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'blue'
        properties: {
          protocol: 'Http'
          path: '/blue'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          // host: hostname
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
