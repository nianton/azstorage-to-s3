targetScope = 'subscription'

@description('Name of the resource group to create the resources in. Leave empty to use naming convention {project}-{environment}-rg.')
param resourceGroupName string
param location string = 'westeurope'
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

var rgName = empty(resourceGroupName) ? '${project}-${environment}-rg' : resourceGroupName

resource group 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgName
  location: location
}

module appDeployment './azure.deploy.bicep' = {
  name: 'appDeployment'
  scope: resourceGroup(group.name)
  params: {
    location: group.location
    environment: environment
    project: project
    archiveContainerName: archiveContainerName
    liveContainerName: liveContainerName
    scheduledContainerName: scheduledContainerName
    awsAccessKey: awsAccessKey
    awsBucket: awsBucket
    awsSecretKey: awsSecretKey
  }
}