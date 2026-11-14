import { commonTags } from '../shared/constants.bicep'

param location string = resourceGroup().location

@minLength(2)
param env string

@minLength(3)
param projectName string

param tags object

@description('A globally unique name for your deployed function app.')
param appName string = 'func-${projectName}-${env}-01'

var deploymentStorageContainerName = 'app-package-${take(appName, 32)}-${take(projectName, 7)}'

var storageAccountAllowSharedKeyAccess = false

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${projectName}${env}'
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: storageAccountAllowSharedKeyAccess
    dnsEndpointType: 'Standard'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
  }
  tags: union(commonTags, tags)
  resource blobServices 'blobServices' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {}
    }
    resource deploymentContainer 'containers' = {
      name: deploymentStorageContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'plan-${projectName}-${env}'
  location: location
  kind: 'linux'
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
  }
  properties: {
    reserved: true
  }
  tags: union(commonTags, tags)
}
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
    }
  }
  tags: union(commonTags, tags)
  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: {
      AzureWebJobsStorage__accountName: storage.name
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
    }
  }
}
