targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'
param password string = 'dummy'
param username string = 'dummy'
param myObjectId string = 'dummy'
param postfix string
param privateip string


resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' existing = {
  name: prefix
}

resource nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: '${prefix}${postfix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${prefix}${postfix}'
        properties: {
          privateIPAddress:privateip
          // privateIPAddress: '10.0.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnet.id}/subnets/${prefix}'
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

resource sshkey 'Microsoft.Compute/sshPublicKeys@2021-07-01' = {
  name: prefix
  location: location
  properties: {
    publicKey: loadTextContent('../ssh/chpinoto.pub')
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: '${prefix}${postfix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      osDisk: {
        name: '${prefix}${postfix}'
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
      computerName: '${prefix}${postfix}'
      adminUsername: username
      adminPassword: password
      customData: loadFileAsBase64('vm.yaml')
      linuxConfiguration:{
        ssh:{
          publicKeys: [
            {
              path:'/home/chpinoto/.ssh/authorized_keys'
              keyData: sshkey.properties.publicKey
            }
          ]
        }
      }
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
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
  }
}

resource nwagentextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vm
  name: 'NetworkWatcherAgentLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
  }
}

var roleVirtualMachineAdministratorName = '1c0163c0-47e6-4577-8991-ea5c82e286e4' //Virtual Machine Administrator Login

resource raMe2VM 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(resourceGroup().id,'raMe2VMHub')
  properties: {
    principalId: myObjectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions',roleVirtualMachineAdministratorName)
  }
}
