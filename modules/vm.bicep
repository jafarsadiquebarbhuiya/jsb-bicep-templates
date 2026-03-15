import { commonTags } from '../shared/constants.bicep'
import { VmConfig } from '../shared/types.bicep'

param config VmConfig

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${config.vmName}-nic'
  location: config.location
  tags: commonTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: config.subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: config.vmName
  location: config.location
  tags: commonTags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: config.vmName
      adminUsername: config.adminUsername
      adminPassword: config.adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        diskSizeGB: 30
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource nginxInstall 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: vm
  name: 'install-nginx'
  location: config.location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    settings: {
      commandToExecute: 'apt-get update && apt-get install -y nginx && echo "<h1>Response from ${config.vmName}</h1>" > /var/www/html/index.html && systemctl enable nginx && systemctl start nginx'
    }
  }
}

output nicId string = nic.id
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
