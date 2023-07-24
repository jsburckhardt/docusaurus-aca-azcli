param appname string
param location string
param tags object

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: appname
  location: location
  tags: tags
}

output apiIdentityId string = appIdentity.id
output apiIdentityPrincipalId string = appIdentity.properties.principalId
output apiIdentityName string = appIdentity.name
