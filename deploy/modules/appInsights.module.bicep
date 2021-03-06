param name string = 'nianton'
param project string
param location string
param tags object = {}

var workspaceName = '${name}-lawp'

resource laWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  location: location
  name: workspaceName
  tags: union(tags, {
    displayName: workspaceName
    projectName: project
  })
  properties: {
    retentionInDays: 90
    sku:{
      name:'PerGB2018'
    }
  }
}

resource appIns 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: name
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    WorkspaceResourceId: laWorkspace.id
  }
}

output id string = appIns.id
output instrumentationKey string = appIns.properties.InstrumentationKey
output workspaceId string = laWorkspace.id