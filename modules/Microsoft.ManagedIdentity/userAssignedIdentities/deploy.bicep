// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : Creates a user assigned identity and optionally assigns RBAC roles to it.
*/

@description('Optional. Name of the User Assigned Identity.')
param parName string = guid(resourceGroup().id)

@description('Optional. Location for all resources.')
param parLocation string = resourceGroup().location

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param parLock string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param parRoleAssignments array = []

@description('Optional. Tags of the resource.')
param parTags object = {}

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param parEnableDefaultTelemetry bool = true

// Create default telemetry deployment
resource resDefaultTelemetry 'Microsoft.Resources/deployments@2022-09-01' = if (parEnableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name, parLocation)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

//  Create user assigned identity
resource resUserMsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: parName
  location: parLocation
  tags: parTags
}

// Create locks on user assigned identity
resource resUserMsiLock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(parLock)) {
  name: '${resUserMsi.name}-${parLock}-lock'
  properties: {
    level: any(parLock)
    notes: parLock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: resUserMsi
}

// Create role assignments
module modUserMsiRoleAssignments '.bicep/nested_roleAssignments.bicep' = [for (roleAssignment, index) in parRoleAssignments: {
  name: '${uniqueString(deployment().name, parLocation)}-UserMSI-Rbac-${index}'
  params: {
    parDescription: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    parPrincipalIds: roleAssignment.principalIds
    parPrincipalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    parRoleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    parCondition: contains(roleAssignment, 'condition') ? roleAssignment.condition : ''
    parDelegatedManagedIdentityResourceId: contains(roleAssignment, 'delegatedManagedIdentityResourceId') ? roleAssignment.delegatedManagedIdentityResourceId : ''
    parResourceId: resUserMsi.id
  }
}]

@description('The name of the user assigned identity.')
output outName string = resUserMsi.name

@description('The resource ID of the user assigned identity.')
output outResourceId string = resUserMsi.id

@description('The principal ID of the user assigned identity.')
output outPrincipalId string = resUserMsi.properties.principalId

@description('The resource group the user assigned identity was deployed into.')
output outResourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output outLocation string = resUserMsi.location
