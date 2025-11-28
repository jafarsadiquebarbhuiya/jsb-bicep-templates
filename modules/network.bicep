param vnet_name string
param tags object
// List of subnet names you want to create
param subnetNames array = [
  'snet-dev-app'
  'snet-dev-db'
  'snet-dev-services'
]

// Create the VNet with an address space
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnet_name
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      for (name, i) in subnetNames: {
        name: name
        properties: {
          // Each subnet takes /24 block inside /16 range
          addressPrefix: '10.0.${i}.0/24'
        }
      }
    ]
  }
}
