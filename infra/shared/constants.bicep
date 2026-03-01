// shared/constants.bicep

import { EnvironmentType, TagsConfig } from './types.bicep'

// ── Exported Variable ──────────────────────────────────────
// Location map per environment
@export()
var locationMap = {
  dev:  'uksouth'
  uat:  'uksouth'
  prod: 'ukwest'
}

// Default lock level per environment
@export()
var lockMap = {
  dev:  'CanNotDelete'
  uat:  'CanNotDelete'
  prod: 'ReadOnly'
}

// ── Exported Functions ─────────────────────────────────────

// Builds a consistent resource name: prefix-env-suffix
// Example: buildName('rg', 'dev', 'christies') → rg-dev-christies
@export()
func buildName(prefix: string, env: EnvironmentType, suffix: string) string =>
  '${prefix}-${env}-${suffix}'

// Builds standard tags object from env and project
// Example: buildTags('dev', 'internal-apim') → { environment: 'dev', project: '...', ... }
@export()
func buildTags(env: EnvironmentType, project: string) TagsConfig => {
  environment: env
  project: project
  managedBy: 'bicep'
  costCenter: env == 'prod' ? 'IT-PROD' : 'IT-NONPROD'
}
