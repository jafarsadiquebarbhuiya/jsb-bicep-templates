targetScope = 'subscription'

@description('Resource Group Name')
param az_rg_name string = 'demo-rg'

@description('Azure Resource Location')
param az_rg_location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: az_rg_name
  location: az_rg_location
  tags: {
    environment: 'dev'
    owner: 'jafar'
  }
}
