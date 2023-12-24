param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'Y1'
  'EP1'
  'EP2'
  'EP3'
])
param skuName string = 'Y1'

param funcWorkerRuntime string = 'dotnet'
param funcExtensionVersion string = '~4'
param funcAppSettings array = []
param funcDeployRepoUrl string = ''
param funcDeployBranch string = ''
param subnetIdForIntegration string = ''
param appInsInstrumentationKey string = ''
param keyVaultName string

@description('Optional. Whether to create a managed identity for the web app -defaults to \'false\'')
param systemAssignedIdentity bool = false

param userAssignedIdentityId string = ''

@description('Optional. Whether to create a linux OS based web app -defaults to \'false\'')
param linux bool = false

var resourceNames = {
  funcStorage: 's${replace(name, '-', '')}'
  funcStorageSecretName: 's${replace(name, '-', '')}Connection'
}

module funcStorage './storageAccount.module.bicep' = {
  name: 'StorageAccount-${resourceNames.funcStorage}'
  params: {
    #disable-next-line BCP334 // erroneous BCP334 warning
    name: resourceNames.funcStorage
    location: location
    tags: tags
    keyVaultName: keyVaultName 
    keyVaultSecretName: resourceNames.funcStorageSecretName
  }
}

module functionApp 'functionApp.module.bicep' = {
  name: 'FunctionApp-${name}'
  params: {
    name: name
    location: location
    tags: tags
    skuName: skuName
    funcStorageName: funcStorage.outputs.name
    funcStorageKeyVaultSecretReference: funcStorage.outputs.keyVaultSecretReference
    funcAppSettings: funcAppSettings
    funcWorkerRuntime: funcWorkerRuntime
    funcExtensionVersion: funcExtensionVersion
    systemAssignedIdentity: systemAssignedIdentity
    userAssignedIdentityId: userAssignedIdentityId
    appInsInstrumentationKey: appInsInstrumentationKey
    funcDeployBranch: funcDeployBranch
    funcDeployRepoUrl: funcDeployRepoUrl
    subnetIdForIntegration: subnetIdForIntegration
    linux: linux
  }
}

output id string = functionApp.outputs.id
output name string = functionApp.outputs.name
output appServicePlanId string = functionApp.outputs.appServicePlanId
output systemAssignedIdentity object = functionApp.outputs.systemAssignedIdentity
output applicationInsights object = functionApp.outputs.applicationInsights
output funcStorage object = funcStorage.outputs
