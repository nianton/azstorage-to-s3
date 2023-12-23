param name string
param projectName string
param location string
param logAnalyticsWorkspaceId string = ''
param tags object = {}

var deployWorkspace = empty(logAnalyticsWorkspaceId)
var workspaceName = 'log-${name}'

resource laWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (deployWorkspace) {
  location: location
  name: workspaceName
  tags: union(tags, {
    displayName: workspaceName
    projectName: projectName
  })
  properties: {
    retentionInDays: 90
    sku:{
      name:'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    WorkspaceResourceId: deployWorkspace ? laWorkspace.id : logAnalyticsWorkspaceId
  }
}

output id string = appInsights.id
output instrumentationKey string = appInsights.properties.InstrumentationKey
output logAnalyticsWorkspaceId string = deployWorkspace ? laWorkspace.id : logAnalyticsWorkspaceId
