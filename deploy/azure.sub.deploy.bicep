targetScope = 'subscription'

@description('Name of the resource group to create the resources in. Leave empty to use naming convention rg-{project}-{environment}.')
param resourceGroupName string = ''
param location string = deployment().location
param project string = 'blob2s3'
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
  name: 'naming'
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

module appDeployment './main.bicep' = {
  name: 'appDeployment'
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
