using 'main.bicep'

param storageAccountName = 'stjsblearning001'

param location = 'Central India'

param storageAccountSku = 'Standard_LRS'

param storageAccountKind = 'StorageV2'

param tags = {
  Environment: 'DEV'
}

param env = 'dev'

param projectName = 'jsb'

param kvSku = 'standard'

param enablePurgeProtection = true

param softDeleteRetentionDays = 90

param netconfig = {
  location: 'Central India'
  vnetName: 'vnet-${projectName}-${env}'
  vnetAddressSpace: ['10.0.0.0/16']
  subnets: [
    { name: 'snet-${projectName}-app-${env}', snetAddressSpace: '10.0.0.0/24' }
    { name: 'snet-${projectName}-appgw-${env}', snetAddressSpace: '10.0.1.0/24' }
  ]
}

param adminUsername = 'azureadmin'
param adminPassword = 'YourP@ssword123!'
