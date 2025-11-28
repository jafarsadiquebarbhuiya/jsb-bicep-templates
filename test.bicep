// common-param
param deployStorage bool
param deployNetwork bool
param deploywebappserviceplan bool
param tags object
param rgdeployment bool
param az_resource_group_name string
targetScope = 'subscription'
module rg 'modules/resource-group.bicep' = if (rgdeployment) {
  scope: subscription()
  params: {
    tags: tags
    az_resource_group_name: az_resource_group_name
    azure_resource_location: azure_resource_location
  }
}

/////Storage-Module
param storage_account_name string
param azure_resource_location string
param storage_account_sku string
param storage_kind string
module paramstorage 'modules/param-storage-account.bicep' = if (deployStorage) {
  name: 'module-paramstorage'
  scope: resourceGroup(az_resource_group_name)
  dependsOn: [rg]
  params: {
    tags: tags
    storage_kind: storage_kind
    azure_resource_location: azure_resource_location
    storage_account_name: storage_account_name
    storage_account_sku: storage_account_sku
  }
}

/////Network-Module
param vnet_name string
module vnet 'modules/network.bicep' = if (deployNetwork) {
  name: 'module-network'
  scope: resourceGroup(az_resource_group_name)
  dependsOn: [rg]
  params: {
    tags: tags
    vnet_name: vnet_name
  }
}

///Webappappservice-Module
param app_service_plan_name string
param web_app_name array
module webappappservice 'modules/app-service-webapp.bicep' = if (deploywebappserviceplan) {
  name: 'module-webappappservice'
  scope: resourceGroup(az_resource_group_name)
  dependsOn: [rg]
  params: {
    app_service_plan_name: app_service_plan_name
    web_app_name: web_app_name
    tags: tags
  }
}
