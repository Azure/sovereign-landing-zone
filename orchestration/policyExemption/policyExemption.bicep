// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This file deploys policy exemptions to a management group.
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

@description('Policy Assignment Name')
param parPolicyAssignmentName string

@description('Policy Assignment Scope Name')
param parPolicyAssignmentScopeName string = parPolicyExemptionManagementGroup

@description('Reference ids of Policies to be exempted')
param parPolicyDefinitionReferenceIds array

@description('Exemption Name')
param parPolicyExemptionName string

@description('Exemption Display Name')
param parPolicyExemptionDisplayName string

@description('Description')
param parDescription string

@description('Management Group for policy exemption')
param parPolicyExemptionManagementGroup string

// Deploy policy exemptions
module modPolicyExemptions '../../dependencies/infra-as-code/bicep/modules/policy/exemptions/policyExemptions.bicep'= {
  scope: managementGroup(parPolicyExemptionManagementGroup)
  name: take('${parDeploymentPrefix}-policy-exemptions${parDeploymentSuffix}', 64)
  params: {
    parPolicyDefinitionReferenceIds: parPolicyDefinitionReferenceIds
    parPolicyAssignmentId: '/providers/microsoft.management/managementgroups/${parPolicyAssignmentScopeName}/providers/microsoft.authorization/policyassignments/${parPolicyAssignmentName}'
    parExemptionName: parPolicyExemptionName
    parExemptionDisplayName: parPolicyExemptionDisplayName
    parDescription: parDescription
  }
}
