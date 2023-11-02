// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : Creates a role assignment at the management group scope
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('Role Definition Id')
param parRoleDefinitionId string

@description('Principal Id of resource for role assignment')
param parPrincipalId string

@description('Service principal type')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param parPrincipalType string

@description('A GUID representing the role assignment name. Default: guid(managementGroup().name, parRoleDefinitionId, parPrincipalId)')
var varRoleAssignmentName = guid(managementGroup().name, parRoleDefinitionId, parPrincipalId)

// Create role assignment
resource resRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: managementGroup()
  name: varRoleAssignmentName
  properties: {
    roleDefinitionId: parRoleDefinitionId
    principalId: parPrincipalId
    principalType: parPrincipalType
  }
}
