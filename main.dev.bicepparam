using 'main.bicep'

param storageAccountName = 'stjsblearning001'

param location = 'eastus'

param storageAccountSku = 'Standard_LRS'

param storageAccountKind = 'StorageV2'

param tags = {
  ResouceType: 'StorageAccount'
  Environment: 'DEV'
  Owner: 'Jafar'
  ManagedBy: 'bicep'
}

param env = 'dev'

param projectName = 'demo'

param kvSku = 'standard'

param enablePurgeProtection = true

param softDeleteRetentionDays = 90
