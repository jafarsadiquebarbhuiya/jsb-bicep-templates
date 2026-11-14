@description('The name of the existing API Management service')
param apimServiceName string

@description('The unique name for the API in APIM')
param apiName string

@description('The backend service URL (required)')
param backendServiceUrl string

// Reference the existing APIM instance
resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimServiceName
}

resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: apiName
  parent: apimService
  properties: {
    apiRevisionDescription: ''
    apiType: 'http'
    apiVersion: ''
    apiVersionDescription: ''
    authenticationSettings: {}
    description: '${apiName}-API'
    displayName: apiName
    path: '/'
    protocols: [
      'https'
    ]
    serviceUrl: backendServiceUrl
    subscriptionRequired: true
    type: 'http'
  }
}
