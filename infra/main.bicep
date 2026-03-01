param storageAccountName string

param location string

param storageAccountSku string

param storageAccountKind string

param tags object

module storageaccount './modules/storage.bicep' = {
  name: 'deploy-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
    storageAccountSku: storageAccountSku
    storageAccountKind: storageAccountKind
  }
}

output storageID string = storageaccount.outputs.storageaccountId

// main.bicep

targetScope = 'subscription'

import { EnvironmentType, ResourceGroupConfig, TagsConfig } from './shared/types.bicep'
import { buildName, buildTags, locationMap, lockMap } from './shared/constants.bicep'

// ── Params ─────────────────────────────────────────────────
param env EnvironmentType
param project string = 'demo'

// ── Variables using exported functions ─────────────────────
var location = locationMap[env] // dev → uksouth, prod → ukwest
var tags = buildTags(env, project) // builds full TagsConfig object

// ── Config objects using exported types ────────────────────
var networkRgConfig ResourceGroupConfig = {
  name: buildName('rg-network', env, project) // rg-network-dev-demo
  location: location
  enableLock: env == 'prod' ? true : false
  lockLevel: 'CanNotDelete'
}

var appsRgConfig ResourceGroupConfig = {
  name: buildName('rg-apps', env, project) // rg-apps-dev-demo
  location: location
  enableLock: false
  lockLevel: 'CanNotDelete'
}

var sharedRgConfig ResourceGroupConfig = {
  name: buildName('rg-shared', env, project) // rg-shared-dev-demo
  location: location
  enableLock: env != 'dev' ? true : false
  lockLevel: 'ReadOnly'
}

// ── Module Calls ───────────────────────────────────────────
module networkRg 'modules/resourceGroup.bicep' = {
  name: 'deploy-rg-network'
  params: {
    env: env
    config: networkRgConfig
    tags: tags
  }
}

module appsRg 'modules/resourceGroup.bicep' = {
  name: 'deploy-rg-apps'
  params: {
    env: env
    config: appsRgConfig
    tags: tags
  }
}

module sharedRg 'modules/resourceGroup.bicep' = {
  name: 'deploy-rg-shared'
  params: {
    env: env
    config: sharedRgConfig
    tags: tags
  }
}

// ── Outputs ────────────────────────────────────────────────
output networkRgId string = networkRg.outputs.rgId
output appsRgId string = appsRg.outputs.rgId
output sharedRgId string = sharedRg.outputs.rgId

output tagsApplied TagsConfig = tags // shows the full tags object that was built
output locationUsed string = location
