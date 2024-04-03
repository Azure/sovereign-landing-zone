// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This is the main entry point for the deployment of the custom compliance initiative. This deployment will create the following resources:
    - Custom role definitions
    - Custom policy initiatives
    - Custom policy assignments
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('The prefix that will be added to all resources created by this deployment.')
@minLength(2)
@maxLength(5)
param parDeploymentPrefix string

@description('The suffix that will be added to management group suffix name the same way to be added to management group prefix names.')
@maxLength(5)
param parDeploymentSuffix string = ''

@description('Enforcement mode for all policy assignments.')
param parPolicyAssignmentEnforcementMode string

@description('Set this to true if any policies in the initiative include a modify effect.')
param parRequireOwnerRolePermission bool = false

@description('Customer specified policy assignments to the root management group of SLZ. No parameters are supported as part of the assignment. DEFAULT: []')
param parCustomerPolicySets array = []

// RBAC Role Definitions Variables - Used For Policy Assignments
var varRBACRoleDefinitionIDs = {
  owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

var varManagementGroupId = '${parDeploymentPrefix}${parDeploymentSuffix}'

//This module will deploy the custom compliance initiative
module modRegulatoryCompliance '../../modules/compliance/customCompliance.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-regulatory-compliance${parDeploymentSuffix}', 64)
  scope: managementGroup(varManagementGroupId)
  params: {
    parDeploymentPrefix: parDeploymentPrefix
    parDeploymentSuffix: parDeploymentSuffix
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parIdentityRoleAssignmentsSubs: []
    parRoleDefinitionIds: [
      (parRequireOwnerRolePermission ? varRBACRoleDefinitionIDs.owner : varRBACRoleDefinitionIDs.reader)
    ]
  }
}

// The following module is used to deploy the customer specified policies
module modUserPolicyAssignment '../../modules/compliance/customerPolicySetAssignments.bicep' = [for policy in parCustomerPolicySets: {
  name: take('${parDeploymentPrefix}-deploy-custpolicyset-assignments-${policy.policySetAssignmentName}${parDeploymentSuffix}', 64)
  params: {
    parDeploymentPrefix: parDeploymentPrefix
    parDeploymentSuffix: parDeploymentSuffix
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicySetDefinitionId: policy.policySetDefinitionId
    parPolicySetAssignmentName: policy.policySetAssignmentName
    parPolicySetAssignmentDisplayName: policy.policySetAssignmentDisplayName
    parPolicySetAssignmentDescription: policy.policySetAssignmentDescription
    parPolicySetManagementGroupAssignmentScope: policy.policySetManagementGroupAssignmentScope
    parPolicyAssignmentParameters: json(policy.policyAssignmentParameters)
  }
  dependsOn: [
    modRegulatoryCompliance
  ]
}]
