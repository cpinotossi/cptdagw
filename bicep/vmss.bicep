param prefix string
param postfix string
param location string
// param virtualMachineScaleSetName string
@secure()
param password string
param username string
param customData string = ''
param isagwbackend bool = false


resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: prefix
}

resource agw 'Microsoft.Network/applicationGateways@2022-09-01' existing = {
  name: prefix
}

resource autoScaleResource 'Microsoft.Insights/autoscaleSettings@2021-05-01-preview' = {
  name: '${prefix}${postfix}'
  location: location
  properties: {
    name: '${prefix}${postfix}'
    targetResourceUri: vmss.id
    enabled: true
    profiles: [
      {
        name: '${prefix}${postfix}'
        capacity: {
          minimum: '1'
          maximum: '3'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 80
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 80
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
        ]
      }
    ]
    predictiveAutoscalePolicy: {
      scaleMode: 'Disabled'
      scaleLookAheadTime: 'PT14M'
    }
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2022-11-01' = {
  name: '${prefix}${postfix}'
  location: location
  properties: {
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'fromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-minimal-focal'
          sku: 'minimal-20_04-lts-gen2'
          version: 'latest'
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [{
          name: '${prefix}${postfix}'
          properties: {
            primary: true
            ipConfigurations: [
              {
                name: '${prefix}${postfix}'
                properties: {
                  subnet: {
                    id: '${vnet.id}/subnets/${prefix}vmss'
                  }
                  primary: true
                  applicationGatewayBackendAddressPools: isagwbackend ? [agw.properties.backendAddressPools[0]] : []
                }
              }
            ]
          }
        }]
      }
      extensionProfile: {
        extensions: []
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
      osProfile: {
        computerNamePrefix: '${prefix}${postfix}'
        adminUsername: username
        adminPassword: password
        customData: !empty(customData) ? base64(customData) : null
        // customData: loadFileAsBase64('vm.nodejs.yaml')
      }
    }
    orchestrationMode: 'Uniform'
    scaleInPolicy: {
      forceDeletion:true
      rules:[
        'Default'
      ]
    }
    overprovision: false
    upgradePolicy: {
      mode: 'Automatic' // If not set to Automatic switch of VMSS at AGW will not take effect.
    }
    platformFaultDomainCount: 1
  }
  sku: {
    name: 'Standard_D2s_v3'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    vnet
  ]
}

// resource vmaadextension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2021-03-01' = {
//   parent: vmName
//   name: 'AADSSHLoginForLinux'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.ActiveDirectory'
//     type: 'AADSSHLoginForLinux'
//     typeHandlerVersion: '1.0'
//     autoUpgradeMinorVersion: true
//   }
//   dependsOn: [
//     vmss
//   ]
// }

