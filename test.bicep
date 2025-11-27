// resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
//   name: 'demo-rg'
//   scope: subscription()
// }

// module storage 'modules/storage-account.bicep' = {
//   name: 'module-storageaccount'
//   scope: rg
// }

param storage_account_name string
param azure_resource_location string
param storage_account_sku string
param tags object
param storage_kind string

module paramstorage 'modules/param-storage-account.bicep' = {
  name: 'module-paramstorage'
  params: {
    tags: tags
    storage_kind: storage_kind
    azure_resource_location: azure_resource_location
    storage_account_name: storage_account_name
    storage_account_sku: storage_account_sku
  }
}
