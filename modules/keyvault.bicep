import { commonTags } from '../shared/constants.bicep'

import { KeyVaultConfig } from '../shared/types.bicep'

param config KeyVaultConfig

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: config.name
  location: config.location
  tags: commonTags
  properties: {
    sku: {
      name: config.sku
      family: 'A'
    }
    tenantId: tenant().tenantId
    enableSoftDelete: true
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    softDeleteRetentionInDays: config.softDeleteRetentionDays
    enablePurgeProtection: config.enablePurgeProtection
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}
