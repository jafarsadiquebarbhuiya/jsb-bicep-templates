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

// Network

@export()
type NsgRuleConfig = {
  name: string
  priority: int
  direction: 'Inbound' | 'Outbound'
  access: 'Allow' | 'Deny'
  protocol: 'Tcp' | 'Udp' | '*'
  sourceAddressPrefix: string
  destinationAddressPrefix: string
  sourcePortRange: string
  destinationPortRange: string
}

@export()
type RouteConfig = {
  environment: string
  project: string
  managedBy: string
  costCenter: string
}

@export()
type NsgIdsConfig = {
  apim: string
  appGw: string
  pe: string
}

@export()
type SubnetConfig = {
  name: string
  snetAddressSpace: string
}

@export()
type NetworkConfig = {
  vnetName: string
  location: string
  vnetAddressSpace: string[]
  subnets: SubnetConfig[]
}

@export()
type VmConfig = {
  vmName: string
  location: string
  adminUsername: string
  @secure()
  adminPassword: string
  subnetId: string
}
