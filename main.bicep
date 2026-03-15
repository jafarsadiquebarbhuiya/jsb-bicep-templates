import { NetworkConfig } from './shared/types.bicep'

param location string

param tags object

@allowed(['dev', 'uat', 'prod'])
param env string

param projectName string

param netconfig NetworkConfig

param storageAccountName string

param storageAccountSku string

param storageAccountKind string

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

param deploykeyVault bool = false
module keyVault 'modules/keyvault.bicep' = if (deploykeyVault) {
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

module network './modules/network.bicep' = {
  name: 'network-deployment'
  params: {
    netconfig: netconfig
  }
}
