targetScope = 'subscription'

@description('Resource Group Name')
param resource_group_name string = 'demo-rg'

@description('Azure Resource Location')
param azure_resource_location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resource_group_name
  location: azure_resource_location
  tags: {
    environment: 'dev'
    owner: 'jafar'
  }
}
