@description('Name of the App Service Subnet')
param subnetName string

@description('Name of the Virtual Network')
param vnetName string

@description('Location for the App Service Subnet')
param location string

@description('Address prefix for the App Service Subnet')
param addressPrefix string = '10.0.1.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

resource appServiceSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: addressPrefix
    serviceEndpoints: [
      {
        service: 'Microsoft.Web'
        locations: [
          location
        ]
      }
    ]
  }
}

output subnetId string = appServiceSubnet.id
output subnetName string = appServiceSubnet.name
