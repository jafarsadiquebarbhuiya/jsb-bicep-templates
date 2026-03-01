@export()
type ResourceConfig = {
  name: string
  location: string
}

@export()
type KeyVaultConfig = {
  name: string
  location: string
  sku: 'standard' | 'premium'
  enablePurgeProtection: bool
  softDeleteRetentionDays: int
}

@export()
type AppconfigConfig = {
  name: string
  location: string
  sku: 'free' | 'standard'
}
