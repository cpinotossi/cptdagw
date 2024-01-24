targetScope='subscription'

var parameters = json(loadTextContent('parameters.json'))

param ipsettings object = {
  vnet: '10.1.0.0/16'
  prefix: '10.1.0.0/24'
  AzureBastionSubnet: '10.1.1.0/24'
  agw: '10.1.2.0/24' 
  vmss:'10.1.3.0/24'
  agwfrontendip: '10.1.2.4'
  prefixvmwin: '10.1.0.4'
}

// var location = resourceGroup().location
param location string = deployment().location
param myobjectid string
param myip string
param prefix string

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: prefix
  location: location
}

module vnetModule 'bicep/vnet.bicep' = {
  scope: resourceGroup(prefix)
  name: 'vnetDeploy'
  params: {
    prefix: prefix
    location: location
    ipsettings: ipsettings
  }
  dependsOn:[
    rg
  ]
}

module vmModule 'bicep/vm.win.bicep' = {
  scope: resourceGroup(prefix)
  name: 'vmDeploy'
  params: {
    prefix: prefix
    location: location
    username: parameters.username
    password: parameters.password
    myObjectId: myobjectid
    postfix: 'win'
    privateip: ipsettings.prefixvmwin
  }
  dependsOn:[
    vnetModule
  ]
}

module agwModule 'bicep/agw.bicep' = {
  scope: resourceGroup(prefix)
  name: 'agwDeploy'
  params: {
    prefix: prefix
    location: location
    hostname: '${prefix}.org'
    frontendip: ipsettings.agwfrontendip
    backendhttpport: 8000
  }
  dependsOn:[
    vnetModule
  ]
}

module vmssBlueModule 'bicep/vmss.bicep' = {
  scope: resourceGroup(prefix)
  name: 'vmssBlueDeploy' 
  params: {
    location: location 
    postfix: 'blue'
    prefix: prefix
    password:parameters.password
    username:parameters.username
    customData: loadTextContent('bicep/vm.nodejs.blue.yaml')
    isagwbackend: true
  }
  dependsOn:[
    agwModule
  ]
}

module vmssGreenModule 'bicep/vmss.bicep' = {
  scope: resourceGroup(prefix)
  name: 'vmssGreenDeploy' 
  params: {
    location: location 
    postfix: 'green'
    prefix: prefix
    password:parameters.password
    username:parameters.username
    customData: loadTextContent('bicep/vm.nodejs.green.yaml')
  }
  dependsOn:[
    agwModule
  ]
}

// module sabModule 'bicep/sab.bicep' = {
//   scope: resourceGroup(prefix)
//   name: 'sabDeploy'
//   params: {
//     prefix: prefix
//     location: location
//     myip: myip
//     myObjectId: myobjectid
//   }
//   dependsOn:[
//     vnetModule
//   ]
// }

// module lawModule 'bicep/law.bicep' = {
//   scope: resourceGroup(prefix)
//   name: 'lawDeploy'
//   params:{
//     prefix: prefix
//     location: location
//   }
//   dependsOn:[
//     agwModule
//   ]
// }
