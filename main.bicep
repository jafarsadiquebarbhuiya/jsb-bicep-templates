param storageAccountName string

param location string

param storageAccountSku string

param storageAccountKind string

param tags object

@allowed(['dev', 'uat', 'prod'])
param env string

param projectName string

param kvSku string

param enablePurgeProtection bool

param softDeleteRetentionDays int

param deploystorageaccount bool = false
module storageaccount './modules/storage.bicep' = if (deploystorageaccount) {
  name: 'deploy-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
    storageAccountSku: storageAccountSku
    storageAccountKind: storageAccountKind
  }
}

// Key-Vault

module keyVault 'modules/keyvault.bicep' = {
  name: 'kv-deploy'
  params: {
    config: {
      name: 'kv-${projectName}-${env}-01'
      location: location
      sku: kvSku
      enablePurgeProtection: enablePurgeProtection
      softDeleteRetentionDays: softDeleteRetentionDays
    }
  }
}
