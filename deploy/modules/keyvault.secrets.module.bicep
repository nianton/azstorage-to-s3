@description('Required. The KeyVault\'s name')
param keyVaultName string

@description('Array of name/value pairs')
param secrets array

module keyVaultSecrets 'keyvault.secret.module.bicep' = [for secret in secrets: {
  name: 'KeyVaultSecret-${secret.name}'
  params: {
    keyVaultName: keyVaultName
    name: secret.name    
    value: secret.value
  }
}]

output secrets array = [for (item, i) in secrets: {
  id: keyVaultSecrets[i].outputs.id
  name: keyVaultSecrets[i].outputs.name
  reference: keyVaultSecrets[i].outputs.reference
  uri: keyVaultSecrets[i].outputs.uri
  uriWithVersion: keyVaultSecrets[i].outputs.uriWithVersion
}]
