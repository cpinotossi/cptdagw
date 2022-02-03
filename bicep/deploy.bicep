targetScope='resourceGroup'

var parameters = json(loadTextContent('../parameters.json'))
var location = resourceGroup().location

module vnetModule 'vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    prefix: parameters.prefix
    location: location
  }
}

module vmModule 'vm.bicep' = {
  name: 'vmDeploy'
  params: {
    prefix: parameters.prefix
    location: location
    username: parameters.username
    password: parameters.password
    myObjectId: parameters.myObjectId
  }
  dependsOn:[
    vnetModule
  ]
}

