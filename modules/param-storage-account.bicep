param storage_account_name string
param azure_resource_location string
param storage_account_sku string
param tags object

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storage_account_name
  location: azure_resource_location
  kind: 'StorageV2'
  sku: {
    name: storage_account_sku
  }
  tags: tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageaccount
  name: 'default'
}

resource container01 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: blobService
  name: 'log01'
  properties: {
    publicAccess: 'None'
  }
}

output StorageAccountName string = storageaccount.name
output StorageAccountID string = storageaccount.id
