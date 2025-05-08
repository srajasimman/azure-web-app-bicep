@description('MySQL Server name')
param serverName string

@description('Location for MySQL Server')
param location string

@description('Environment name')
param environmentName string

@description('MySQL administrator login name')
param administratorLogin string

@description('MySQL administrator password')
@secure()
param administratorLoginPassword string

@description('MySQL SKU name')
param skuName string = 'B_Gen5_1'

@description('MySQL storage size in GB')
param storageSizeGB int = 20

@description('Enable geo-redundant backups')
param enableGeoRedundantBackup bool = false

@description('Database name')
param databaseName string = 'appdb'

resource mySqlServer 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLS1_2'
    storageProfile: {
      storageMB: storageSizeGB * 1024
      backupRetentionDays: 7
      geoRedundantBackup: enableGeoRedundantBackup ? 'Enabled' : 'Disabled'
    }
    version: '8.0'
    createMode: 'Default'
  }
  sku: {
    name: skuName
    tier: startsWith(skuName, 'B') ? 'Basic' : startsWith(skuName, 'GP') ? 'GeneralPurpose' : 'MemoryOptimized'
    capacity: int(last(split(skuName, '_')))
    size: '${storageSizeGB}GB'
    family: contains(skuName, 'Gen5') ? 'Gen5' : 'Gen4'
  }
  tags: {
    Environment: environmentName
  }
}

resource mySqlFirewallRules 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01' = {
  parent: mySqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource mySqlDatabase 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  parent: mySqlServer
  name: databaseName
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

output mySqlServerName string = mySqlServer.name
output mySqlServerFqdn string = mySqlServer.properties.fullyQualifiedDomainName
output databaseName string = databaseName
