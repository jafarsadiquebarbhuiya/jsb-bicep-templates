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

param netconfig = {
  location: location
  vnetName: 'vnet-${projectName}-${env}'
  vnetAddressSpace: ['10.0.0.0/16']
  subnets: [
    { name: 'snet-${projectName}-${env}-app', snetAddressSpace: '10.0.0.0/24' }
    { name: 'snet-${projectName}-${env}-appgw', snetAddressSpace: '10.0.1.0/24' }
  ]
}
