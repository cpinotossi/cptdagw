targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'
param ipsettings object
// param ipsettings object = {
//   vnet: '10.0.0.0/16'
//   prefix: '10.0.0.0/24'
//   AzureBastionSubnet: '10.0.1.0/24'
//   agw: '10.0.2.0/24' 
// }

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: prefix
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        ipsettings.vnet
      ]
    }
    subnets: [
      {
        name: prefix
        properties: {
          addressPrefix: ipsettings.prefix
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: ipsettings.AzureBastionSubnet
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: '${prefix}agw'
        properties: {
          addressPrefix: ipsettings.agw
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
        name: '${prefix}vmss'
        properties: {
          addressPrefix: ipsettings.vmss
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

resource pubipbastion 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-09-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    dnsName:'${prefix}.bastion.azure.com'
    enableTunneling: true
    enableShareableLink: true
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
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

resource pdns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location:'global'
  name: '${prefix}.io'
}

resource pdnslink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: pdns
  name: prefix
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource pdnsz 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: pdns
  name: 'ws'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: ipsettings.agwfrontendip
      }
    ]
  }
}
