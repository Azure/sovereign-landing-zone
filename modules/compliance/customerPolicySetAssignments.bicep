// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY :
    -This module deploys customer configured policy set assignments to the root management group.
    - Only policy set definition with no parameters or parameters with default values are supported for customer assignment.
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('The prefix that will be added to all resources created by this deployment.')
@minLength(2)
@maxLength(5)
param parDeploymentPrefix string

@description('The suffix that will be added to management group suffix name the same way to be added to management group prefix names.')
@maxLength(5)
param parDeploymentSuffix string

@description('Enforcement mode for all policy assignments.')
param parPolicyAssignmentEnforcementMode string

@description('Deployed policy set definition id ')
param parPolicySetDefinitionId string

@description('Name for the policy set assignment')
@minLength(1)
param parPolicySetAssignmentName string

@description('Display name for the policy set assignment')
param parPolicySetAssignmentDisplayName string

@description('descritpion for the policy set assignment')
param parPolicySetAssignmentDescription string

@description('An object containing the parameter values for the policy to be assigned.')
param parPolicyAssignmentParameters object = {}

@description('Management group scope for the policy assignment')
param parPolicySetManagementGroupAssignmentScope string = ''

var varManagementGroupId = empty(parPolicySetManagementGroupAssignmentScope) ? '${parDeploymentPrefix}${parDeploymentSuffix}' : contains(toLower(parPolicySetManagementGroupAssignmentScope), '/providers/microsoft.management/managementgroups/') ? replace(toLower(parPolicySetManagementGroupAssignmentScope), '/providers/microsoft.management/managementgroups/', '') : parPolicySetManagementGroupAssignmentScope

var varRbacRoleDefinitionIds = {
  owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  networkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  aksContributor: 'ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'
}

// Module - Policy Assignments - Root Management Group
module modUserPolicyAssignment '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = {
  scope: managementGroup(varManagementGroupId)
  name: take('${parDeploymentPrefix}-polAssi-CustomerPolicySet-intRoot-${parPolicySetAssignmentName}${parDeploymentSuffix}', 64)
  params: {
    parPolicyAssignmentDefinitionId: parPolicySetDefinitionId
    parPolicyAssignmentName: take('${parPolicySetAssignmentName}', 24)
    parPolicyAssignmentDisplayName: parPolicySetAssignmentDisplayName
    parPolicyAssignmentDescription: parPolicySetAssignmentDescription
    parPolicyAssignmentParameters: parPolicyAssignmentParameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}
