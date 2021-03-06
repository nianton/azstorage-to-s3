param location string = resourceGroup().location
param project string = 'aztransfer'
param environment string = 'dev'
param scheduledContainerName string = 'scheduled'
param archiveContainerName string = 'archive'
param liveContainerName string = 'live'

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
  dataStorage: 's${toLower(replace(resourcePrefix, '-', ''))}data'
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

module dataStorage './modules/storage.module.bicep' = {
  name: 'dataStorage'
  params: {
    name: resourceNames.dataStorage
    location: location
    tags: defaultTags
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for containerName in containerNames: {
  name: '${resourceNames.dataStorage}/default/${containerName}'
  dependsOn:[
    dataStorage
  ]
}]

module funcApp './modules/functionApp.module.bicep' = {
  name: 'funcApp'
  params: {
    location: location
    name: resourceNames.funcApp
    tags: defaultTags    
    funcAppSettings: [
      {
        name: 'DataStorageConnection'
        value: dataStorage.outputs.connectionString
      }
      {
        name: 'AwsAccessKey'
        value: awsAccessKey
      }
      {
        name: 'AwsSecretKey'
        value: awsSecretKey
      }
      {
        name: 'AwsBucket'
        value: awsBucket
      }
      {
        name: 'LiveContainerName'
        value: liveContainerName
      }
      {
        name: 'ScheduledContainerName'
        value: scheduledContainerName
      }
      {
        name: 'ArchiveContainerName'
        value: archiveContainerName
      }
    ]
  }
}

output funcDeployment object = funcApp
output dataStorage object = dataStorage