import { commonTags } from '../shared/constants.bicep'

import { NetworkConfig } from '../shared/types.bicep'

param netconfig NetworkConfig

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: netconfig.vnetName
  location: netconfig.location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: netconfig.vnetAddressSpace
    }
    subnets: [
      for subnet in netconfig.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.snetAddressSpace
        }
      }
    ]
  }
}

output vnetId string = virtualNetwork.id
output subnetIds array = [
  for (subnet, i) in netconfig.subnets: {
    name: subnet.name
    id: virtualNetwork.properties.subnets[i].id
  }
]
