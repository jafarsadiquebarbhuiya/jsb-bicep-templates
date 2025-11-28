targetScope = 'subscription'

@description('Resource Group Name')
param az_resource_group_name string
@description('Azure Resource Location')
param azure_resource_location string
param tags object
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: az_resource_group_name
  location: azure_resource_location
  tags: tags
}
