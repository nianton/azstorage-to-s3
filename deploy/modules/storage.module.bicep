param location string
param name string
param tags object = {}
param kind string = 'StorageV2'
param sku object = {
  name: 'Standard_LRS'
  tier: 'Standard'
}

resource storage 'Microsoft.Storage/storageAccounts@2019-06-01' = {  
  name: toLower(replace(name, '-', ''))  
  location: location  
  kind: kind
  sku: sku
  tags: union(tags, {
    displayName: name
  })  
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }  
}

output id string = storage.id
output name string = storage.name
output primaryKey string = listKeys(storage.id, storage.apiVersion).keys[0].value
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value}'