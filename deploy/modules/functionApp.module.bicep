param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'java'
  'dotnet'
  'node'
  'python'
  'powershell'
])
param funcWorkerRuntime string = 'dotnet'
param funcExtensionVersion string = '~4'
param funcNetFrameworkVersion string = 'v6.0'
param funcAppSettings array = []

#disable-next-line secure-secrets-in-params // Contains the key vault reference for the storage account's connection string 
param funcStorageKeyVaultSecretReference string
param funcStorageName string

@description('Optional. Whether to create a managed identity for the web app -defaults to \'false\'')
param systemAssignedIdentity bool = false

param userAssignedIdentityId string = ''

@description('Optional. Whether to create a linux OS based web app -defaults to \'false\'')
param linux bool = false

@allowed([
  'Y1'
  'EP1'
  'EP2'
  'EP3'
])
param skuName string = 'Y1'

@description('Optional. The container to be deployed -fully qualified container tag expected.')
param containerApplicationTag string = ''

param funcDeployRepoUrl string = ''
param funcDeployBranch string = ''
param subnetIdForIntegration string = ''
param appInsInstrumentationKey string = ''

var skuTier = skuName == 'Y1' ? 'Dynamic' : 'Elastic'
var funcAppServicePlanName = 'plan-${name}'

var funcAppInsName = 'appins-${name}'
var createSourceControl = !empty(funcDeployRepoUrl)
var createNetworkConfig = !empty(subnetIdForIntegration)
var createAppInsights = empty(appInsInstrumentationKey)

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentityId) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentityId) ? 'UserAssigned' : 'None')
var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: empty(userAssignedIdentityId) ? null : {
    '${userAssignedIdentityId}': {}
  }
} : null

var linuxFxVersion = linux ? (empty(containerApplicationTag) ? 'DOCKER|mcr.microsoft.com/azure-functions/dotnet:4' : 'DOCKER|${containerApplicationTag}') : null

var siteConfigPartNetFrameworkVersion = funcWorkerRuntime == 'dotnet' ? {
  netFrameworkVersion: funcNetFrameworkVersion
} : {}

var siteConfigPartLinuxFxVersion = linux ? {
  linuxFxVersion: linuxFxVersion
} : {}

module funcAppIns './appInsights.module.bicep' = if (createAppInsights) {
  name: 'AppInsights-${funcAppInsName}-Deployment'
  params: {
    name: funcAppInsName
    location: location
    projectName: name
    tags: tags
  }
}

resource funcAppServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: funcAppServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: linux ? 'linux,functionapp' : 'functionapp'
  properties: {
    reserved: linux
  }
}

resource funcStorage 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: funcStorageName
}

resource funcApp 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  kind: linux ? 'functionapp,linux' : 'functionapp'
  identity: identity
  properties: {
    serverFarmId: funcAppServicePlan.id    
    keyVaultReferenceIdentity: !empty(userAssignedIdentityId) ? userAssignedIdentityId : null
    siteConfig: union({
      ftpsState: 'Disabled'
      appSettings: concat([
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: funcExtensionVersion
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: funcWorkerRuntime
        }
        {
          name: 'AzureWebJobsDashboard'
          value: funcStorageKeyVaultSecretReference
        }
        {
          name: 'AzureWebJobsStorage'
          value: funcStorageKeyVaultSecretReference 
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStorage.name};AccountKey=${funcStorage.listKeys().keys[0].value}' //
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(name)
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: createAppInsights ? funcAppIns.outputs.instrumentationKey : appInsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${createAppInsights ? funcAppIns.outputs.instrumentationKey : appInsInstrumentationKey}'
        }
      ], funcAppSettings)      
    }, 
    siteConfigPartLinuxFxVersion, 
    siteConfigPartNetFrameworkVersion)
    httpsOnly: true
    clientAffinityEnabled: false
  }
  tags: union(tags, {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${funcAppServicePlan.name}': 'Resource'
  }, createAppInsights ? {'hidden-link: /app-insights-resource-id': resourceId('Microsoft.Insights/components', funcAppInsName)} : {})
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2022-09-01' = if (createNetworkConfig) {
  parent: funcApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetIdForIntegration
  }
}

resource funcAppSourceControl 'Microsoft.Web/sites/sourcecontrols@2022-09-01' = if (createSourceControl) {
  parent: funcApp
  name: 'web'
  properties: {
    branch: funcDeployBranch
    repoUrl: funcDeployRepoUrl
    isManualIntegration: true
  }
}

output id string = funcApp.id
output name string = funcApp.name
output appServicePlanId string = funcAppServicePlan.id
output systemAssignedIdentity object = systemAssignedIdentity ? {
  tenantId: funcApp.identity.tenantId
  principalId: funcApp.identity.principalId
  type: funcApp.identity.type
} : {}
output applicationInsights object = funcAppIns
output storage object = funcStorage
