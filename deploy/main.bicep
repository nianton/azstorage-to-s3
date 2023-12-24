param location string = resourceGroup().location

@description('Container name to periodically transfer')
param scheduledContainerName string = 'scheduled'

@description('Container to move the files from the scheduled run')
param archiveContainerName string = 'archive'

@description('Container name to monitor for file additions')
param liveContainerName string = 'live'

@description('The function application repository to be deployed -change if forked')
param functionAppRepoUrl string = 'https://github.com/nianton/azstorage-to-s3'

@description('The function application repository branch to be deployed')
param functionAppRepoBranch string = 'main'

@description('Naming module names output')
param naming object

param defaultTags object = {}

@allowed([
  'standard'
  'premium'
])
@description('Azure Key Vault SKU')
param keyVaultSku string = 'standard'

@allowed([
  'Y1'
  'EP1'
  'EP2'
  'EP3'
])
@description('Azure Function plan, Y1: Consumption, EPx: Elastic Premium')
param azureFunctionPlanSkuName string = 'Y1'

@description('AWS S3 bucket name')
param awsBucket string

@secure()
@description('AWS AccessKey - value will be stored in the Key Vault')
param awsAccessKey string

@secure()
@description('AWS SecretKey - value will be stored in the Key Vault')
param awsSecretKey string

// Resource names for the deployment, based on Naming's module output
var resourceNames = {
  funcApp: naming.functionApp.nameUnique
  keyVault: naming.keyVault.nameUnique
  dataStorage: naming.storageAccount.nameUnique
  userAssignedIdentity: 'uai-${naming.functionApp.name}'
}

// Secret names in the Key Vault
var secretNames = {
  awsAccessKey: 'awsAccessKey'
  awsSecretKey: 'awsSecretKey'  
  dataStorageConnectionString: 'dataStorageConnectionString'
}

// Containers for data storage account
var containerNames = [
  archiveContainerName
  liveContainerName
  scheduledContainerName
]

// Storage Account containing the data
module dataStorage './modules/storageAccount.module.bicep' = {
  name: 'StorageAccount-${resourceNames.dataStorage}'
  params: {
    name: resourceNames.dataStorage
    location: location
    tags: defaultTags
    keyVaultName: keyVault.outputs.name
    keyVaultSecretName: secretNames.dataStorageConnectionString
  }
}

// Blob Containers based on the provided naming
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for containerName in containerNames: {
  name: '${resourceNames.dataStorage}/default/${containerName}'
  dependsOn:[
    dataStorage
  ]
}]

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: resourceNames.userAssignedIdentity
  location: location
}

module keyVault 'modules/keyvault.module.bicep' =  {
  name: 'KeyVault-${resourceNames.keyVault}'
  params: {
    name: resourceNames.keyVault
    location: location
    tags: defaultTags
    skuName: keyVaultSku
    enabledForTemplateDeployment: true
    accessPolicies: [
      {
        tenantId: userAssignedIdentity.properties.tenantId
        objectId: userAssignedIdentity.properties.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
    secrets: [
      {
        name: secretNames.awsAccessKey
        value: awsAccessKey
      }
      {
        name: secretNames.awsSecretKey
        value: awsSecretKey
      }
    ]
  }
}

// Function Application (with respected Application Insights and Storage Account)
// with the respective configuration, and deployment of the application
module funcAppComposite './modules/functionAppComposite.module.bicep' = {
  name: 'FunctionAppComposite-${resourceNames.funcApp}'
  params: {
    location: location
    name: resourceNames.funcApp
    userAssignedIdentityId: userAssignedIdentity.id
    tags: defaultTags
    skuName: azureFunctionPlanSkuName
    keyVaultName: keyVault.outputs.name
    funcDeployRepoUrl: functionAppRepoUrl
    funcDeployBranch: functionAppRepoBranch
    funcAppSettings: [
      {
        name: 'DataStorageConnection'
        value: dataStorage.outputs.keyVaultSecretReference
      }
      {
        name: 'AwsAccessKey'
        value: keyVault.outputs.secrets[0].reference
      }
      {
        name: 'AwsSecretKey'
        value: keyVault.outputs.secrets[1].reference
      }
      {
        name: 'AwsBucketName'
        value: awsBucket
      }
      {
        name: 'LiveContainer'
        value: liveContainerName
      }
      {
        name: 'ScheduledContainer'
        value: scheduledContainerName
      }
      {
        name: 'ArchiveContainer'
        value: archiveContainerName
      }
    ]
  }
}

output funcDeployment object = funcAppComposite.outputs
output dataStorage object = dataStorage
output keyVault object = keyVault
