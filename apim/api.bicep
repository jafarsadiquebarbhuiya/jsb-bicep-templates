@description('The name of the existing API Management service')
param apimServiceName string

@description('The unique name for the API in APIM')
param apiName string

@description('The backend service URL (required)')
param backendServiceUrl string

param apiVersionSetName string

param apiVersion string

// Reference the existing APIM instance
resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimServiceName
}

resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2024-05-01' = {
  parent: apimService
  name: apiVersionSetName
  properties: {
    displayName: apiName
    versioningScheme: 'Segment'
  }
}
resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: apiName
  parent: apimService
  properties: {
    apiRevisionDescription: ''
    apiType: 'http'
    apiVersion: 'v1'
    apiVersionSetId: apiVersionSet.id
    apiVersionDescription: ''
    authenticationSettings: {}
    description: '${apiName}-API'
    displayName: apiName
    path: 'products'
    protocols: [
      'https'
    ]
    serviceUrl: backendServiceUrl
    subscriptionRequired: true
    type: 'http'
    format: 'openapi'
    value: loadTextContent('./products-api.openapi.yaml')
  }
}

// API-level inbound policy
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: loadTextContent('./products-api-policy.xml')
  }
}

output apiId string = api.id
output apiUrl string = 'https://${apimService.name}.azure-api.net/products/${apiVersion}'
