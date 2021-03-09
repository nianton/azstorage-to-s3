param location string = resourceGroup().location
param project string = 'blob2s3'
param environment string = 'dev'

@description('Container name to periodically transfer')
param scheduledContainerName string = 'scheduled'

@description('Container to move the files from the scheduled run')
param archiveContainerName string = 'archive'

@description('Container name to monitor for file additions')
param liveContainerName string = 'live'

@description('Azure Key Vault SKU')
param keyVaultSku string = 'Standard'

@description('AWS S3 bucket name')
param awsBucket string

@secure()
@description('AWS AccessKey')
param awsAccessKey string

@secure()
@description('AWS SecretKey')
param awsSecretKey string

// Resource names - establish naming convention
var resourcePrefix = '${project}-${environment}'
var resourceNames = {
  funcApp: '${resourcePrefix}-func'
  keyVault: '${resourcePrefix}-kv'
  dataStorage: 's${toLower(replace(resourcePrefix, '-', ''))}data'
}
var secretNames = {
  awsAccessKey: 'awsAccessKey'
  awsSecretKey: 'awsSecretKey'  
  dataStorageConnectionString: '${resourceNames.dataStorage}ConnectionString'
}

// Default tags to be added to all resources
var defaultTags = {
  environment: environment
  project: project
}

// Containers for data storage account
var containerNames = [
  archiveContainerName
  liveContainerName
  scheduledContainerName
]

// Storage Account containing the data
module dataStorage './modules/storage.module.bicep' = {
  name: 'dataStorage'
  params: {
    name: resourceNames.dataStorage
    location: location
    tags: defaultTags
  }
}

// Blob Containers based on the provided naming
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for containerName in containerNames: {
  name: '${resourceNames.dataStorage}/default/${containerName}'
  dependsOn:[
    dataStorage
  ]
}]

// KeyVault for storing the secret
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: resourceNames.keyVault
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: keyVaultSku
    }
    accessPolicies: [
      {
        tenantId: funcApp.outputs.identity.tenantId
        objectId: funcApp.outputs.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
  tags: defaultTags
}

// KeyVault secrets provisioning
resource keyVaultSecretDataStorage 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  name: '${keyVault.name}/${secretNames.dataStorageConnectionString}'
  properties: {
    value: dataStorage.outputs.connectionString
  }
}

resource keyVaultSecretAwsAccessKey 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  name: '${keyVault.name}/${secretNames.awsAccessKey}'
  properties: {
    value: awsAccessKey
  }
}

resource keyVaultSecretAwsSecretKey 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  name: '${keyVault.name}/${secretNames.awsSecretKey}'
  properties: {
    value: awsSecretKey
  }
}

// Function Application (with respected Application Insights and Storage Account)
// with the respective configuration, and deployment of the application
module funcApp './modules/functionApp.module.bicep' = {
  name: 'funcApp'
  params: {
    location: location
    name: resourceNames.funcApp
    managedIdentity: true
    tags: defaultTags    
    funcDeployBranch: 'main'
    funcDeployRepoUrl: 'https://github.com/nianton/azstorage-to-s3'
    funcAppSettings: [
      {
        name: 'DataStorageConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
      }
      {
        name: 'AwsAccessKey'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.awsAccessKey})'
      }
      {
        name: 'AwsSecretKey'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.awsSecretKey})'
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

output funcDeployment object = funcApp
output dataStorage object = dataStorage
output keyVault object = {
  id: keyVault.id
  name: keyVault.name
}