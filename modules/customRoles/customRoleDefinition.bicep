// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : Creates a custom role definition at the management group scope
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('Array of actions for the roleDefinition')
param parActions array = []

@description('Array of notActions for the roleDefinition')
param parNotActions array = []

@description('Friendly name of the role definition')
param parRoleName string

@description('Detailed description of the role definition')
param parRoleDescription string

var varRoleDefName = guid(managementGroup().id, parRoleName)

// Create the role definition
resource resRoleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: varRoleDefName
  properties: {
    roleName: parRoleName
    description: parRoleDescription
    type: 'customRole'
    permissions: [
      {
        actions: parActions
        notActions: parNotActions
      }
    ]
    assignableScopes: [
      managementGroup().id
    ]
  }
}

output outRoleDefinitionId string = resRoleDef.id
