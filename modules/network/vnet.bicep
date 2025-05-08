@description('Location for the Virtual Network')
param location string

@description('Environment name')
param environmentName string

@description('Virtual Network name')
param vnetName string = '${environmentName}-vnet'

@description('Address prefix for the Virtual Network')
param vnetAddressPrefix string = '10.0.0.0/16'

resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output vnetAddressPrefix string = vnet.properties.addressSpace.addressPrefixes[0]
