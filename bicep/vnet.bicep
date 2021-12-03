targetScope='resourceGroup'

var parameters = json(loadTextContent('../parameters.json'))

resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: '${parameters.prefix}'
  location: parameters.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${parameters.prefix}agw'
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
        name: 'AzureFunctionSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: '${parameters.prefix}sn'
        properties: {
          addressPrefix: '10.0.2.0/24'
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

resource nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: '${parameters.prefix}nic'
  location: parameters.location
  properties: {
    ipConfigurations: [
      {
        name: '${parameters.prefix}ipconfig'
        properties: {
          privateIPAddress: '10.0.2.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnet.id}/subnets/${parameters.prefix}sn'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: '${parameters.prefix}'
  location: parameters.location
  zones: [
    '1'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      osDisk: {
        name: '${parameters.prefix}'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${parameters.prefix}'
      adminUsername: '${parameters.username}'
      adminPassword: 'demo!pass123'
      customData: loadFileAsBase64('vm.yaml')
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource vmaadextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vm
  name: 'AADSSHLoginForLinux'
  location: parameters.location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
  }
}

var roleVirtualMachineAdministratorName = '1c0163c0-47e6-4577-8991-ea5c82e286e4' //Virtual Machine Administrator Login

resource raMe2VM 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(resourceGroup().id,'raMe2VMHub')
  properties: {
    principalId: parameters.myObjectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions',roleVirtualMachineAdministratorName)
  }
}

resource pubipbastion 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${parameters.prefix}bastion'
  location: parameters.location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: '${parameters.prefix}bastion'
  location: parameters.location
  sku: {
    name:'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: '${parameters.prefix}bastion'
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
