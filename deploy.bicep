targetScope='subscription'

var parameters = json(loadTextContent('parameters.json'))
param ipsettings object = {
  vnet: '10.1.0.0/16'
  prefix: '10.1.0.0/24'
  AzureBastionSubnet: '10.1.1.0/24'
  agw: '10.1.2.0/24' 
  agwfrontendip: '10.1.2.4'
  agwbackendip: '10.1.0.4'
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

module vmModule 'bicep/vm.nodejs.bicep' = {
  scope: resourceGroup(prefix)
  name: 'vmDeploy'
  params: {
    prefix: prefix
    location: location
    username: parameters.username
    password: parameters.password
    myObjectId: myobjectid
    postfix: 'nodejs'
    privateip: ipsettings.agwbackendip
  }
  dependsOn:[
    vnetModule
  ]
}

module sabModule 'bicep/sab.bicep' = {
  scope: resourceGroup(prefix)
  name: 'sabDeploy'
  params: {
    prefix: prefix
    location: location
    myip: myip
    myObjectId: myobjectid
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
    cnCertificateFrontend: parameters.cnCertificateFrontend
    certpassword: parameters.certpassword
    cnCABackend: parameters.cnCABackend
    frontendip: ipsettings.agwfrontendip
    backendip: ipsettings.agwbackendip
  }
  dependsOn:[
    sabModule
  ]
}

module lawModule 'bicep/law.bicep' = {
  scope: resourceGroup(prefix)
  name: 'lawDeploy'
  params:{
    prefix: prefix
    location: location
  }
  dependsOn:[
    agwModule
  ]
}
