param storageAccountName string

param location string

param storageAccountKind string

param storageAccountSku string

param tags object

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
}

output storageaccountId string = storage.id

var storageNames = [
  'stjsblearning002'
  'stjsblearning003'
]

resource storage01 'Microsoft.Storage/storageAccounts@2023-01-01' = [
  for name in storageNames: {
    name: name
    location: location
    tags: tags
    sku: { name: 'Standard_LRS' }
    kind: 'StorageV2'
  }
]

var envs = ['dev', 'uat', 'prod']

resource storage02 'Microsoft.Storage/storageAccounts@2023-01-01' = [
  for (env, i) in envs: {
    name: 'stjsblearning${env}'
    location: location
    tags: tags
    sku: { name: 'Standard_LRS' }
    kind: 'StorageV2'
  }
]
