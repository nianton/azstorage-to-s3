param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Optional. Array of access policy configurations, schema ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies?tabs=json#microsoftkeyvaultvaultsaccesspolicies-object')
param accessPolicies array = []

@description('Optional. Secrets array with name/value pairs')
param secrets array = []

@description('Optional. Whether the keyVault will be enabled for template deployment -defaults to true.')
param enabledForTemplateDeployment bool = true

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    accessPolicies: accessPolicies
    enabledForTemplateDeployment: enabledForTemplateDeployment
  }
  tags: tags
}

module secretsDeployment 'keyvault.secrets.module.bicep' = if (!empty(secrets)) {
  name: 'KeyVault-${name}-Secrets'
  params: {
    keyVaultName: keyVault.name
    secrets: secrets
  }
}

output id string = keyVault.id
output name string = keyVault.name
output secrets array = secretsDeployment.outputs.secrets
