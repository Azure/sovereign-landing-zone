// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This file will deploy a policy remediation to a management group.
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

@description('Remediation Name.')
param parPolicyRemediationName string

@description('Policy Assignment Id.')
param parPolicyAssignmentId string

@description('Reference ids of policy to be remediated.')
param parPolicyDefinitionReferenceId string

@description('Policy assignment scope.')
param parManagementGroupScope string

// Deploy the policy remediation
module modPolicyRemediation '../../modules/compliance/policyRemediation.bicep' = {
  scope: managementGroup(parManagementGroupScope)
  name: take('${parDeploymentPrefix}-${parPolicyRemediationName}${parDeploymentSuffix}', 64)
  params: {
    parPolicyRemediationName: parPolicyRemediationName
    parPolicyAssignmentId: parPolicyAssignmentId
    parPolicyDefinitionReferenceId: parPolicyDefinitionReferenceId
  }
}
