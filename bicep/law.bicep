targetScope='resourceGroup'

var parameters = json(loadTextContent('../parameters.json'))

resource law 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: parameters.prefix
  location: parameters.location
}

resource sab 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: parameters.prefix
}

resource agw 'Microsoft.Network/applicationGateways@2021-03-01' existing = {
  name: parameters.prefix
}

resource diaagw 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: parameters.prefix
  properties: {
    storageAccountId: sab.id
    workspaceId: law.id
  }
  scope: agw
}


