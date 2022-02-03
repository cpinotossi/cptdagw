targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'

resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: '${prefix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${prefix}agw'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints:[
            {
                'service': 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: '${prefix}'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource pubipbastion 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          publicIPAddress: {
            id: pubipbastion.id
          }
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}
