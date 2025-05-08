@description('Name of the Front Door resource')
param frontDoorName string

@description('Location for the Front Door resource')
param location string

@description('Environment name')
param environmentName string

@description('Backend Storage URL for the frontend')
param backendStorageUrl string

@description('Whether to enable Web Application Firewall')
param enableWAF bool = false

var frontendEndpointName = '${frontDoorName}-endpoint'
var backendPoolName = '${frontDoorName}-backend-pool'
var loadBalancingSettingsName = '${frontDoorName}-lb-settings'
var healthProbeSettingsName = '${frontDoorName}-health-probe'
var routingRuleName = '${frontDoorName}-routing-rule'

resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: frontDoorName
  location: location
  properties: {
    enabledState: 'Enabled'
    friendlyName: frontDoorName

    frontendEndpoints: [
      {
        name: frontendEndpointName
        properties: {
          hostName: '${frontDoorName}.azurefd.net'
          sessionAffinityEnabledState: 'Disabled'
          sessionAffinityTtlSeconds: 0
          webApplicationFirewallPolicyLink: enableWAF ? {
            id: resourceId('Microsoft.Network/FrontDoorWebApplicationFirewallPolicies', '${frontDoorName}-waf-policy')
          } : null
        }
      }
    ]

    backendPools: [
      {
        name: backendPoolName
        properties: {
          backends: [
            {
              address: replace(replace(backendStorageUrl, 'https://', ''), '/', '')
              backendHostHeader: replace(replace(backendStorageUrl, 'https://', ''), '/', '')
              enabledState: 'Enabled'
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 100
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors', frontDoorName, 'loadBalancingSettings', loadBalancingSettingsName)
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors', frontDoorName, 'healthProbeSettings', healthProbeSettingsName)
          }
        }
      }
    ]

    healthProbeSettings: [
      {
        name: healthProbeSettingsName
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 30
          healthProbeMethod: 'HEAD'
          enabledState: 'Enabled'
        }
      }
    ]

    loadBalancingSettings: [
      {
        name: loadBalancingSettingsName
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
          additionalLatencyMilliseconds: 0
        }
      }
    ]

    routingRules: [
      {
        name: routingRuleName
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors', frontDoorName, 'frontendEndpoints', frontendEndpointName)
            }
          ]
          acceptedProtocols: [
            'Http'
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          enabledState: 'Enabled'
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors', frontDoorName, 'backendPools', backendPoolName)
            }
          }
        }
      }
    ]
  }
}

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = if (enableWAF) {
  name: '${frontDoorName}-waf-policy'
  location: 'global'
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'DefaultRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}

output frontDoorUrl string = 'https://${frontDoor.properties.frontendEndpoints[0].properties.hostName}'
output frontDoorId string = frontDoor.id
