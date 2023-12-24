targetScope = 'subscription'

@description('Name of the resource group to create the resources in. Leave empty to use naming convention rg-{project}-{environment}-{location}.')
param resourceGroupName string = ''

@description('Optional. The Azure region to deploy all resources to -defaults to the deployment\'s location.')
param location string = deployment().location

@description('Optional. The project name to deploy -it will be part of the naming convention.')
param project string = 'blob2s3'

@description('Optional. The environment name (e.g. dev, test, prod) to deploy -it will be part of the naming convention.')
param environment string = 'dev'

@description('Optional. The name of the storage account container to sync on schedule via TimeTrigger.')
param scheduledContainerName string = 'scheduled'

@description('Optional. The name of the storage account container to archive the files after they have been transfered to the S3 bucket.')
param archiveContainerName string = 'archive'

@description('Optional. The name of the storage account container to monitor for changes, when files are added they will be automatically synced to the S3 bucket.')
param liveContainerName string = 'live'

@description('AWS S3 bucket name, the sync destination')
param awsBucket string

@secure()
@description('AWS AccessKey')
param awsAccessKey string

@secure()
@description('AWS SecretKey')
param awsSecretKey string

var rgName = empty(resourceGroupName) ? 'rg-${project}-${environment}-${location}' : resourceGroupName

var tags = {
  project: project
  environment: environment
}

resource resGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgName
  location: location
}

module naming 'modules/naming.module.bicep' = {
  name: 'Naming-Module'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    suffix: [
      project
      environment
      '**location**'
    ]
    uniqueLength: 4
  }
}

module mainDeployment './main.bicep' = {
  name: 'MainDeployment'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    naming: naming.outputs.names
    archiveContainerName: archiveContainerName
    liveContainerName: liveContainerName
    scheduledContainerName: scheduledContainerName
    awsAccessKey: awsAccessKey
    awsBucket: awsBucket
    awsSecretKey: awsSecretKey
    defaultTags: tags
  }
}

output dataStorage object = mainDeployment.outputs.dataStorage
output funcDeployment object = mainDeployment.outputs.funcDeployment
output keyVault object = mainDeployment.outputs.keyVault
