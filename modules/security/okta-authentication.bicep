@description('App Service name to configure Okta auth')
param appServiceName string

@description('Okta tenant URL')
param oktaTenantUrl string

@description('Okta client ID')
param oktaClientId string

@description('Okta client secret')
@secure()
param oktaClientSecret string

resource appService 'Microsoft.Web/sites@2021-03-01' existing = {
  name: appServiceName
}

resource appServiceConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: appService
  name: 'web'
  properties: {
    appSettings: [
      {
        name: 'Okta__Domain'
        value: oktaTenantUrl
      }
      {
        name: 'Okta__ClientId'
        value: oktaClientId
      }
      {
        name: 'Okta__ClientSecret'
        value: oktaClientSecret
      }
      {
        name: 'Okta__AuthorizationServerId'
        value: 'default'
      }
    ]
  }
}

output configuredAppServiceName string = appService.name
