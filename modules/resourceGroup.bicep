// modules/resourceGroup.bicep

targetScope = 'subscription'

import { EnvironmentType, ResourceGroupConfig, TagsConfig } from '../shared/types.bicep'
import { lockMap } from '../shared/constants.bicep'

param env EnvironmentType
param config ResourceGroupConfig
param tags TagsConfig

// ── Deploy Resource Group ──────────────────────────────────
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: config.name
  location: config.location
  tags: tags
}

// ── Deploy Lock (conditional) ──────────────────────────────
// Only deploys if enableLock is true in the config
resource lock 'Microsoft.Authorization/locks@2020-05-01' = if (config.enableLock) {
  name: 'lock-${config.name}'
  scope: rg
  properties: {
    level: lockMap[env]       // uses exported lockMap variable
    notes: 'Managed by Bicep — ${env} environment'
  }
}

// ── Outputs ────────────────────────────────────────────────
output rgId string = rg.id
output rgName string = rg.name
output lockApplied bool = config.enableLock
