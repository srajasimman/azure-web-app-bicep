@description('Name of the App Service')
param appServiceName string

@description('Location for the App Service')
param location string

@description('Environment name')
param environmentName string

@description('App Service Plan SKU name')
param skuName string = 'B1'

@description('App Service Plan capacity (number of instances)')
param skuCapacity int = 1

@description('Virtual Network name')
param vnetName string = '${environmentName}-vnet'

@description('Subnet name for App Service integration')
param appServiceSubnetName string = 'app-service-subnet'

var appServicePlanName = '${appServiceName}-plan'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

resource appServiceSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: appServiceSubnetName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    reserved: false
  }
  tags: {
    Environment: environmentName
    Application: 'Backend API'
  }
}

resource appService 'Microsoft.Web/sites@2021-03-01' = {
  name: appServiceName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v6.0'
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environmentName
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'  // Routes all outbound traffic through the VNet
        }
      ]
    }
    virtualNetworkSubnetId: appServiceSubnet.id  // Link to subnet for integration
  }
  tags: {
    Environment: environmentName
    Application: 'Backend API'
  }
}

// Configure VNet integration for the App Service
resource networkConfig 'Microsoft.Web/sites/networkConfig@2021-03-01' = {
  parent: appService
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: appServiceSubnet.id
    swiftSupported: true
  }
}

output appServiceName string = appService.name
output apiUrl string = 'https://${appService.properties.defaultHostName}'
output vnetName string = vnet.name
output subnetName string = appServiceSubnet.name
