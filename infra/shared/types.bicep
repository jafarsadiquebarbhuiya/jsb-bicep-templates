// shared/types.bicep

@export()
type EnvironmentType = 'dev' | 'uat' | 'prod'

@export()
type LockLevel = 'CanNotDelete' | 'ReadOnly'

@export()
type TagsConfig = {
  environment: EnvironmentType
  project: string
  managedBy: string
  costCenter: string
}

@export()
type ResourceGroupConfig = {
  name: string
  location: string
  enableLock: bool
  lockLevel: LockLevel
}
