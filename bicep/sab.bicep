targetScope='resourceGroup'

var parameters = json(loadTextContent('../parameters.json'))

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: parameters.prefix
}

resource sa 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: parameters.prefix
  location: parameters.location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/${parameters.prefix}agw'
          action: 'Allow'
          state: 'Succeeded'
        }
      ]
      ipRules: [
        {
          value: '93.230.208.209'
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
    accessTier: 'Hot'
  }
}

resource sab 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: sa
  name: 'default'
}

resource sac 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: sab
  name: parameters.prefix
  properties: {
    publicAccess: 'Blob'
  }
}

var roleStorageBlobDataContributorName = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor

resource rablobcontributor 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(resourceGroup().id,'rablobcontributort')
  properties: {
    principalId: parameters.myObjectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/RoleDefinitions',roleStorageBlobDataContributorName)
  }
}
