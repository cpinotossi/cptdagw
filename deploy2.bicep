targetScope='resourceGroup'

param prefix string = 'cptdazagw'
param location string = 'eastus'
param pathrulescount int = 99

resource pubip 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: prefix
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    ipAddress: '4.246.190.128'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource sab 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: prefix
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: false
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource sabs 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: sab
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: false
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
    isVersioningEnabled: false
  }
}

resource agw 'Microsoft.Network/applicationGateways@2022-09-01' = {
  name: prefix
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/default'
          }
        }
      }
    ]
    sslCertificates: []
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIpIPv4'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pubip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: '${prefix}001'
        properties: {
          backendAddresses: []
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: prefix
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: prefix
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/frontendPorts/port_80'
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
        }
      }
    ]
    listeners: []
    urlPathMaps: [
      {
        name: prefix
        properties: {
          defaultBackendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendAddressPools/${prefix}001'
          }
          defaultBackendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendHttpSettingsCollection/${prefix}'
          }
          pathRules: [for i in range(0,pathrulescount):{
              name: '${prefix}${i}'
              properties: {
                paths: [
                  '/00${i}*'
                ]
                backendAddressPool: {
                  id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendAddressPools/${prefix}001'
                }
                backendHttpSettings: {
                  id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/backendHttpSettingsCollection/${prefix}'
                }
              }
            }]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: prefix
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 10
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/httpListeners/${prefix}'
          }
          urlPathMap: {
            id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/urlPathMaps/${prefix}'
          }
        }
      }
    ]
    routingRules: []
    probes: []
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: prefix
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.3.0.0/24'
          // applicationGatewayIPConfigurations: [
          //   {
          //     id: '${resourceId('Microsoft.Network/applicationGateways', prefix)}/gatewayIPConfigurations/appGatewayIpConfig'
          //   }
          // ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

