var azure_resource_location = 'eastus'
var storage_account_sku = 'Standard_LRS'
var az_container_name = 'web'
var storage_account_prefix = 'st'
var deployment_environment = 'dev'

var az_storage_account_name = toLower('${storage_account_prefix}${deployment_environment}${uniqueString(resourceGroup().name)}')

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: az_storage_account_name
  location: azure_resource_location
  kind: 'StorageV2'
  sku: {
    name: storage_account_sku
  }
  tags: {
    environment: deployment_environment
    owner: 'jafar'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storageaccount
  name: 'default'
}

resource container01 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: blobService
  name: az_container_name
  properties: {
    publicAccess: 'None'
  }
}
