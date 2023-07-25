// scope
targetScope = 'subscription'

// parameters
param function string = 'sampleyaml'
param env string = 'dev'
param location string = 'australiaeast'


// variables
var resGroupName = 'rsg-${function}-${env}'
var managedEnvName = 'me-${function}-${env}'
var containerRegistryName = 'acr${function}${env}'
var logWorkspaceName = 'lw-${function}-${env}'
var appname = 'app-${function}-${env}'

var tags = { blogdemo: appname }

// resource group
resource resGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resGroupName
  location: location
  tags: {
    project: 'edifice'
    team: 'casg'
    purpose: 'casg sites'
  }
}

module managedEnvironment 'core/host/container-apps-environment.bicep' = {
  scope: resGroup
  name: managedEnvName
  params: {
    location: location
    name: managedEnvName
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}

module containerApp 'core/host/container-app.bicep' = {
  scope: resGroup
  name: 'containerapp-${appname}'
  params: {
    name: appname
    location: location
    tags: tags
    imageName: ''
    containerName: 'docusaurus'
    containerAppsEnvironmentName: managedEnvironment.name
    containerRegistryName: containerRegistryName
    identityName: appIdentity.name
    targetPort: 3000
  }
  dependsOn: [
    containerRegistry
    managedEnvironment
    containerRegistryAccess
  ]
}

module logAnalyticsWorkspace 'core/monitor/loganalytics.bicep' = {
  name: 'loganalytics'
  scope: resGroup
  params: {
    name: logWorkspaceName
    location: location
    tags: tags
  }
}

module appIdentity 'core/security/identity.bicep' = {
  name: appname
  scope: resGroup
  params: {
    appname: appname
    location: location
    tags: tags
  }
}

module containerRegistry 'core/host/container-registry.bicep' = {
  name: containerRegistryName
  scope: resGroup
  params: {
    name: containerRegistryName
    location: location
    tags: tags
    workspaceId: logAnalyticsWorkspace.outputs.id
  }
}

module containerRegistryAccess 'core/security/registry-access.bicep' = {
  scope: resGroup
  name: '${deployment().name}-registry-access'
  params: {
    containerRegistryName: containerRegistryName
    principalId: appIdentity.outputs.apiIdentityPrincipalId
  }
  dependsOn: [
    containerRegistry
  ]
}

output apiIdentityId string = appIdentity.outputs.apiIdentityId
output apiIdentityPrincipalId string = appIdentity.outputs.apiIdentityPrincipalId
output apiIdentityName string = appIdentity.outputs.apiIdentityName
output managedEnvironmentId string = managedEnvironment.outputs.managedEnvironmentId
output containerRegistryName string = containerRegistry.outputs.name
output containerRegistryServer string = containerRegistry.outputs.loginServer
output resourceGroupName string = resGroup.name
output containerAppEndPoint string = containerApp.outputs.uri
