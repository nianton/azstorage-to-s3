@description('Required. The name of the storage account, will be sanitized.')
@minLength(3)
param name string

@description('The location of the storage account, defaults to the resource group\'s location.')
param location string = resourceGroup().location

@description('Optional. Tags to be added to the resource, .')
param tags object = {}

@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
@description('Optional. Storage Account kind, defaults to "StorageV2".')
param kind string = 'StorageV2'

@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_LRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
@description('Optional. Sku name, defaults to "Standard_LRS".')
param skuName string = 'Standard_LRS'

param keyVaultName string = ''
param keyVaultSecretName string = ''

var createSecretInKeyVault = !empty(keyVaultName) && !empty(keyVaultSecretName)

resource storage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  #disable-next-line BCP334 // Erroneous warning BCP334
  name: take(toLower(replace(name, '-', '')), 24)
  location: location
  kind: kind
  sku: {
    name: skuName
  }
  tags: union(tags, {
    displayName: name
  })
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

module keyVaultSecret 'keyvault.secret.module.bicep' = if (createSecretInKeyVault) {
  name: 'StorageAccount-${name}-KeyVaultSecret-${keyVaultSecretName}'
  params: {
    keyVaultName: keyVaultName
    name: keyVaultSecretName
    value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name}};AccountKey=${storage.listKeys().keys[0].value}'
  }
}

output id string = storage.id
output name string = storage.name
output primaryEndpoints object = storage.properties.primaryEndpoints
output keyVaultSecretUri string = createSecretInKeyVault ? keyVaultSecret.outputs.uri : ''
output keyVaultSecretReference string = createSecretInKeyVault ? keyVaultSecret.outputs.reference : ''
