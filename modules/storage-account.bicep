var storage_accounts = [
  {
    name: 'webjsbdev01'
    kind: 'StorageV2'
    location: 'eastus'
  }
  {
    name: 'webjsbdev02'
    kind: 'StorageV2'
    location: 'eastus'
  }
]

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = [
  for st in storage_accounts: {
    name: st.name
    kind: st.kind
    location: st.location
    sku: {
      name: 'Standard_LRS'
    }
  }
]

resource storageaccount1 'Microsoft.Storage/storageAccounts@2021-02-01' = [
  for (st, index) in storage_accounts: {
    name: '${st.name}${index}'
    kind: st.kind
    location: st.location
    sku: {
      name: 'Standard_LRS'
    }
  }
]

@allowed([
  'westus'
  'uksouth'
])
param location string = 'westus'
resource storageaccount3 'Microsoft.Storage/storageAccounts@2021-02-01' = [
  for (st, index) in storage_accounts: if (location == st.location) {
    name: '${st.name}${index + 1}'
    kind: st.kind
    location: st.location
    sku: {
      name: 'Standard_LRS'
    }
  }
]
