// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : Creates a Policy Remediation for a Policy Set Assignment or a Policy Assignment in a Management Group
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('Exemption Name')
param parPolicyRemediationName string

@description('Policy Set Assignment id')
param parPolicyAssignmentId string

@description('Reference ids of Policy to be remediated')
param parPolicyDefinitionReferenceId string

@allowed([
  'ExistingNonCompliant'
  'ReEvaluateCompliance'
])
@description('Remediation Discovery Mode - ExistingNonCompliant')
param parResourceDiscoveryMode string = 'ExistingNonCompliant'

// Policy Remediation for Policy Set Assignment
resource resPolicySetRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = if (parPolicyDefinitionReferenceId != null) {
  name: take('${parPolicyRemediationName}-${parPolicyDefinitionReferenceId}', 64)
  properties: {
    policyAssignmentId: parPolicyAssignmentId
    policyDefinitionReferenceId: parPolicyDefinitionReferenceId
    resourceDiscoveryMode: parResourceDiscoveryMode
  }
}

// Policy Remediation for Policy Assignment
resource resPolicyRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = if (parPolicyDefinitionReferenceId == null) {
  name: parPolicyRemediationName
  properties: {
    policyAssignmentId: parPolicyAssignmentId
    resourceDiscoveryMode: parResourceDiscoveryMode
  }
}
