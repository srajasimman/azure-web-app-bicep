@description('Environment name (dev, test, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('MySQL Server admin login')
param mysqlAdminLogin string

@description('MySQL Server admin password')
@secure()
param mysqlAdminPassword string

@description('Okta Tenant URL')
param oktaTenantUrl string

@description('Okta Client ID')
param oktaClientId string

@description('Okta Client Secret')
@secure()
param oktaClientSecret string

// Network resources
module vnet '../../modules/network/vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    vnetName: '${environmentName}-vnet'
    location: location
    environmentName: environmentName
  }
}

module appServiceSubnet '../../modules/network/app-subnet.bicep' = {
  name: 'appServiceSubnetDeploy'
  params: {
    vnetName: vnet.outputs.vnetName
    subnetName: 'app-service-subnet'
    location: location
  }
}

// Frontend resources
module storageAccount '../../modules/frontend/storage-account.bicep' = {
  name: 'storageAccountDeploy'
  params: {
    storageAccountName: 'fe${environmentName}storage'
    location: location
    environmentName: environmentName
  }
}

module frontDoor '../../modules/frontend/front-door.bicep' = {
  name: 'frontDoorDeploy'
  params: {
    frontDoorName: 'fe-${environmentName}-frontdoor'
    location: 'global'
    environmentName: environmentName
    backendStorageUrl: storageAccount.outputs.primaryEndpointWeb
  }
}

// Backend resources
module appService '../../modules/backend/app-service.bicep' = {
  name: 'appServiceDeploy'
  params: {
    appServiceName: 'be-${environmentName}-api'
    location: location
    environmentName: environmentName
    vnetName: vnet.outputs.vnetName
    appServiceSubnetName: appServiceSubnet.outputs.subnetName
  }
}

module mySql '../../modules/backend/mysql.bicep' = {
  name: 'mySqlDeploy'
  params: {
    serverName: 'be-${environmentName}-mysql'
    location: location
    environmentName: environmentName
    administratorLogin: mysqlAdminLogin
    administratorLoginPassword: mysqlAdminPassword
  }
}

module backendStorage '../../modules/backend/storage.bicep' = {
  name: 'backendStorageDeploy'
  params: {
    storageAccountName: 'be${environmentName}storage'
    location: location
    environmentName: environmentName
  }
}

// Security resources
module oktaAuth '../../modules/security/okta-authentication.bicep' = {
  name: 'oktaAuthDeploy'
  params: {
    appServiceName: appService.outputs.appServiceName
    oktaTenantUrl: oktaTenantUrl
    oktaClientId: oktaClientId
    oktaClientSecret: oktaClientSecret
  }
}

// Outputs
output frontendStorageAccountName string = storageAccount.outputs.storageAccountName
output frontendUrl string = frontDoor.outputs.frontDoorUrl
output backendApiUrl string = appService.outputs.apiUrl
output backendStorageAccountName string = backendStorage.outputs.storageAccountName
