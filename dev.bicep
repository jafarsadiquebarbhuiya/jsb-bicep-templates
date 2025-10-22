resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: 'demo-rg'
  scope: subscription()
}

module storage 'modules/storage-account.bicep' = {
  name: 'module-storageaccount'
  scope: rg
}
