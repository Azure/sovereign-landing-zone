// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
@sys.description('Required. The IDs of the principals to assign the role to.')
param parPrincipalIds array

@sys.description('Required. The name of the role to assign. If it cannot be found you can specify the role definition ID instead.')
param parRoleDefinitionIdOrName string

@sys.description('Required. The resource ID of the resource to apply the role assignment to.')
param parResourceId string

@sys.description('Optional. The principal type of the assigned principal ID.')
@allowed([
  'ServicePrincipal'
  'Group'
  'User'
  'ForeignGroup'
  'Device'
  ''
])
param parPrincipalType string = ''

@sys.description('Optional. The description of the role assignment.')
param parDescription string = ''

@sys.description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container"')
param parCondition string = ''

@sys.description('Optional. Version of the condition.')
@allowed([
  '2.0'
])
param parConditionVersion string = '2.0'

@sys.description('Optional. Id of the delegated managed identity resource.')
param parDelegatedManagedIdentityResourceId string = ''

var varBuiltInRoleNames = {
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Log Analytics Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')
  'Log Analytics Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '73c42c96-874c-492b-b04d-ab87d138a893')
  'Managed Application Contributor Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '641177b8-a67a-45b9-a033-47bc880bb21e')
  'Managed Application Operator Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c7393b34-138c-406f-901b-d8cf2b17e6ae')
  'Managed Applications Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b9331d33-8a36-4f8c-b097-4f54124fdb44')
  'Managed Identity Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e40ec5ca-96e0-45a2-b4ff-59039f2c2b59')
  'Managed Identity Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
  'Monitoring Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '749f88d5-cbae-40b8-bcfc-e573ddc772fa')
  'Monitoring Metrics Publisher': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')
  'Monitoring Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05')
  'Resource Policy Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '36243c78-bf99-498c-9df9-86d9f8d28608')
  'User Access Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
}

resource resUserMsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: any(last(split(parResourceId, '/')))
}

resource resRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in parPrincipalIds: {
  name: guid(resUserMsi.id, principalId, parRoleDefinitionIdOrName)
  properties: {
    description: parDescription
    roleDefinitionId: varBuiltInRoleNames[?parRoleDefinitionIdOrName] ?? parRoleDefinitionIdOrName
    principalId: principalId
    principalType: !empty(parPrincipalType) ? any(parPrincipalType) : null
    condition: !empty(parCondition) ? parCondition : null
    conditionVersion: !empty(parConditionVersion) && !empty(parCondition) ? parConditionVersion : null
    delegatedManagedIdentityResourceId: !empty(parDelegatedManagedIdentityResourceId) ? parDelegatedManagedIdentityResourceId : null
  }
  scope: resUserMsi
}]
