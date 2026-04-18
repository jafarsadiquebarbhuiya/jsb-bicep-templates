import { NetworkConfig } from './shared/types.bicep'

param storageAccountName string
param location string
param storageAccountSku string
param storageAccountKind string
param tags object
param projectName string
param kvSku string
param enablePurgeProtection bool
param softDeleteRetentionDays int
param deploystorageaccount bool = false
param deploykeyVault bool = false
param netconfig NetworkConfig
param adminUsername string
@secure()
param adminPassword string

@allowed(['dev', 'uat', 'prod'])
param env string

module storageaccount './modules/storage.bicep' = if (deploystorageaccount) {
  name: 'deploy-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
    storageAccountSku: storageAccountSku
    storageAccountKind: storageAccountKind
  }
}

module keyVault 'modules/keyvault.bicep' = if (deploykeyVault) {
  name: 'kv-deploy'
  params: {
    config: {
      name: 'kv-${projectName}-${env}-01'
      location: location
      sku: kvSku
      enablePurgeProtection: enablePurgeProtection
      softDeleteRetentionDays: softDeleteRetentionDays
    }
  }
}

module network './modules/network.bicep' = {
  name: 'network-deployment'
  params: {
    netconfig: netconfig
  }
}

module vm1 './modules/vm.bicep' = {
  name: 'vm1-deployment'
  params: {
    config: {
      vmName: 'vm-${projectName}-${env}-01'
      location: location
      adminUsername: adminUsername
      adminPassword: adminPassword
      subnetId: network.outputs.subnetIds[0].id
    }
  }
}

param deployvirtualMachin bool = false
module virtualMachin './modules/vm.bicep' = if (deployvirtualMachin) {
  name: 'vm2-deployment'
  params: {
    config: {
      vmName: 'vm-${projectName}-${env}-02'
      location: location
      adminUsername: adminUsername
      adminPassword: adminPassword
      subnetId: network.outputs.subnetIds[0].id
    }
  }
}

param deployFunctionApp bool = false

module functionApp './modules/functionApp.bicep' = if (deployFunctionApp) {
  name: 'functionapp-deployment'
  params: {
    appName: 'func-${projectName}-${env}-01'
    location: location
    resourceToken: toLower(uniqueString(subscription().id, location))
  }
}
