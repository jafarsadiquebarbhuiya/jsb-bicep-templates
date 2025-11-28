param location string = resourceGroup().location
param app_service_plan_name string
param web_app_name array
param tags object

// App Service Plan (Free tier)
resource appPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: app_service_plan_name
  location: location
  tags: tags
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

// Two Web Apps sharing the same App Service Plan
resource webApps 'Microsoft.Web/sites@2023-01-01' = [
  for name in web_app_name: {
    name: name
    location: location
    tags: tags
    properties: {
      serverFarmId: appPlan.id
      httpsOnly: true
    }
  }
]
