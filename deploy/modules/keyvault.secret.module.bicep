@description('Required. The KeyVault\'s name')
param keyVaultName string

@description('Required. The name of the secret in KeyVault.')
param name string

@secure()
@description('Required. The value of the secret in the KeyVault.')
param value string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: name
  properties: {
    value: value
  }
}

output id string = keyVaultSecret.id
output name string = name
output type string = keyVaultSecret.type
output uri string = keyVaultSecret.properties.secretUri
output uriWithVersion string = keyVaultSecret.properties.secretUriWithVersion
output reference string = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${name})'
