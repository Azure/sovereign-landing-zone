// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : Deploys the Management Groups and Subscriptions for the Sovereign Landing Zone
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

@description('An array containing a list of Subscription IDs that the System-assigned Managed Identity associated to the policy assignment will be assigned to in addition to the Management Group the policy is deployed/assigned to.')
param parIdentityRoleAssignmentsSubs array

@description('The role definition ids for permissions.')
param parRoleDefinitionIds array

// Managment Groups Varaibles - Used For Policy Assignments
var varManagementGroupIDs = {
  intRoot: '${parDeploymentPrefix}${parDeploymentSuffix}'
  platform: '${parDeploymentPrefix}-platform${parDeploymentSuffix}'
  platformManagement: '${parDeploymentPrefix}-platform-management${parDeploymentSuffix}'
  platformConnectivity: '${parDeploymentPrefix}-platform-connectivity${parDeploymentSuffix}'
  platformIdentity: '${parDeploymentPrefix}-platform-identity${parDeploymentSuffix}'
  landingZones: '${parDeploymentPrefix}-landingzones${parDeploymentSuffix}'
  landingZonesCorp: '${parDeploymentPrefix}-landingzones-corp${parDeploymentSuffix}'
  landingZonesOnline: '${parDeploymentPrefix}-landingzones-online${parDeploymentSuffix}'
  landingZonesConfidentialCorp: '${parDeploymentPrefix}-landingzones-confidential-corp${parDeploymentSuffix}'
  landingZonesConfidentialOnline: '${parDeploymentPrefix}-landingzones-confidential-online${parDeploymentSuffix}'
  decommissioned: '${parDeploymentPrefix}-decommissioned${parDeploymentSuffix}'
  sandbox: '${parDeploymentPrefix}-sandbox${parDeploymentSuffix}'
}

var varTopLevelManagementGroupResourceID = '/providers/Microsoft.Management/managementGroups/${varManagementGroupIDs.intRoot}'

// Policy Assignments Modules Variables

var varGlobalCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzGlobalCustom.json')
var varGlobalCustomPolicies = {
  definitionID: replace('${varGlobalCustomPoliciesLibDef.id}.v${varGlobalCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_global_custom.tmpl.json')
  libDefinition: varGlobalCustomPoliciesLibDef
  version: replace('v${varGlobalCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varLandingZonesPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzLandingZoneCustom.json')
var varLandingZonesPolicies = {
  definitionID: replace('${varLandingZonesPoliciesLibDef.id}.v${varLandingZonesPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_landing_zones_custom.tmpl.json')
  libDefinition: varLandingZonesPoliciesLibDef
  version: replace('v${varLandingZonesPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varConfidentialCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzConfidentialCustom.json')
var varConfidentialCustomPolicies = {
  definitionID: replace('${varConfidentialCustomPoliciesLibDef.id}.v${varConfidentialCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_confidential_custom.tmpl.json')
  libDefinition: varConfidentialCustomPoliciesLibDef
  version: replace('v${varConfidentialCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varCorpCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzCorpCustom.json')
var varCorpCustomPolicies = {
  definitionID: replace('${varCorpCustomPoliciesLibDef.id}.v${varCorpCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_corp_custom.tmpl.json')
  libDefinition: varCorpCustomPoliciesLibDef
  version: replace('v${varCorpCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varOnlineCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzOnlineCustom.json')
var varOnlineCustomPolicies = {
  definitionID: replace('${varOnlineCustomPoliciesLibDef.id}.v${varOnlineCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_online_custom.tmpl.json')
  libDefinition: varOnlineCustomPoliciesLibDef
  version: replace('v${varOnlineCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varPlatformCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzPlatformCustom.json')
var varPlatformCustomPolicies = {
  definitionID: replace('${varPlatformCustomPoliciesLibDef.id}.v${varPlatformCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_platform_custom.tmpl.json')
  libDefinition: varPlatformCustomPoliciesLibDef
  version: replace('v${varPlatformCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varConnectivityCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzConnectivityCustom.json')
var varConnectivityCustomPolicies = {
  definitionID: replace('${varConnectivityCustomPoliciesLibDef.id}.v${varConnectivityCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_connectivity_custom.tmpl.json')
  libDefinition: varConnectivityCustomPoliciesLibDef
  version: replace('v${varConnectivityCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varIdentityCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzIdentityCustom.json')
var varIdentityCustomPolicies = {
  definitionID: replace('${varIdentityCustomPoliciesLibDef.id}.v${varIdentityCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_identity_custom.tmpl.json')
  libDefinition: varIdentityCustomPoliciesLibDef
  version: replace('v${varIdentityCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varManagementCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzManagementCustom.json')
var varManagementCustomPolicies = {
  definitionID: replace('${varManagementCustomPoliciesLibDef.id}.v${varManagementCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_management_custom.tmpl.json')
  libDefinition: varManagementCustomPoliciesLibDef
  version: replace('v${varManagementCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varSandboxCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzSandboxCustom.json')
var varSandboxCustomPolicies = {
  definitionID: replace('${varSandboxCustomPoliciesLibDef.id}.v${varSandboxCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_sandbox_custom.tmpl.json')
  libDefinition: varSandboxCustomPoliciesLibDef
  version: replace('v${varSandboxCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varDecommissionedCustomPoliciesLibDef = loadJsonContent('../../custom/policies/definitions/slzDecommissionedCustom.json')
var varDecommissionedCustomPolicies = {
  definitionID: replace('${varDecommissionedCustomPoliciesLibDef.id}.v${varDecommissionedCustomPoliciesLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('../../custom/policies/assignments/policy_assignment_deploy_slz_decommissioned_custom.tmpl.json')
  libDefinition: varDecommissionedCustomPoliciesLibDef
  version: replace('v${varDecommissionedCustomPoliciesLibDef.properties.metadata.version}', '.', '')
}

var varDeploymentNameWrappers = {
  basePrefix: parDeploymentPrefix
  #disable-next-line no-loc-expr-outside-params //Policies resources are not deployed to a region, like other resources, but the metadata is stored in a region hence requiring this to keep input parameters reduced. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  baseSuffixTenantAndManagementGroup: deployment().location
}

@description('Timestamp with format yyyyMMddTHHmmssZ. Default value set to Execution Timestamp to avoid deployment contention.')
param parTimestamp string = utcNow()

var varModuleDeploymentNames = {
  modPolicyAssignmentIntRootSlzCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-slzCustom-intRoot-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentPlatformCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-platformCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentSandboxCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-sandboxCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentDecommissionedCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-decomCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentLandingZoneCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-landingZoneCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentCorpCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-corpCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentOnlineCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-onlineCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentConfidentialCorpCustom_Confidential: take('${varDeploymentNameWrappers.basePrefix}-polAssi-confidentialCorpCustom_Confidential-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentConfidentialCorpCustom_Corp: take('${varDeploymentNameWrappers.basePrefix}-polAssi-confidentialCorpCustom_Corp-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentConfidentialOnlineCustom_Confidential: take('${varDeploymentNameWrappers.basePrefix}-polAssi-confidentialOnlineCustom_Confidential-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentConfidentialOnlineCustom_Online: take('${varDeploymentNameWrappers.basePrefix}-polAssi-confidentialOnlineCustom_Online-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentConnectivityCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-connectivityCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentIdentityCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-identityCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
  modPolicyAssignmentManagementCustom: take('${varDeploymentNameWrappers.basePrefix}-polAssi-managementCustom-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}-${parTimestamp}', 64)
}

// Module - Policy Assignments - Root Management Group
module modPolicyAssignmentGlobalCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varGlobalCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentIntRootSlzCustom
  scope: managementGroup(varManagementGroupIDs.intRoot)
  params: {
    parPolicyAssignmentDefinitionId: varGlobalCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varGlobalCustomPolicies.libAssignment.properties.description} ${varGlobalCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varGlobalCustomPolicies.libAssignment.properties.displayName} ${varGlobalCustomPolicies.version}'
    parPolicyAssignmentName: take('${varGlobalCustomPolicies.libAssignment.name}${varGlobalCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Decommisioned Management Group
module modPolicyAssignmentDecommissionedCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varDecommissionedCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentDecommissionedCustom
  scope: managementGroup(varManagementGroupIDs.decommissioned)
  params: {
    parPolicyAssignmentDefinitionId: varDecommissionedCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varDecommissionedCustomPolicies.libAssignment.properties.description} ${varDecommissionedCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varDecommissionedCustomPolicies.libAssignment.properties.displayName} ${varDecommissionedCustomPolicies.version}'
    parPolicyAssignmentName: take('${varDecommissionedCustomPolicies.libAssignment.name}${varDecommissionedCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Management Group
module modPolicyAssignmentLandingZoneCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varLandingZonesPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentLandingZoneCustom
  scope: managementGroup(varManagementGroupIDs.landingZones)
  params: {
    parPolicyAssignmentDefinitionId: varLandingZonesPolicies.definitionID
    parPolicyAssignmentDescription: '${varLandingZonesPolicies.libAssignment.properties.description} ${varLandingZonesPolicies.version}'
    parPolicyAssignmentDisplayName: '${varLandingZonesPolicies.libAssignment.properties.displayName} ${varLandingZonesPolicies.version}'
    parPolicyAssignmentName: take('${varLandingZonesPolicies.libAssignment.name}${varLandingZonesPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Confidential Corp Management Group
module modPolicyAssignmentConfidentialCorpCustom_Confidential '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varConfidentialCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentConfidentialCorpCustom_Confidential
  scope: managementGroup(varManagementGroupIDs.landingZonesConfidentialCorp)
  params: {
    parPolicyAssignmentDefinitionId: varConfidentialCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varConfidentialCustomPolicies.libAssignment.properties.description} ${varConfidentialCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varConfidentialCustomPolicies.libAssignment.properties.displayName} ${varConfidentialCustomPolicies.version}'
    parPolicyAssignmentName: take('${varConfidentialCustomPolicies.libAssignment.name}${varConfidentialCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

module modPolicyAssignmentConfidentialCorpCustom_Corp '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varCorpCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentConfidentialCorpCustom_Corp
  scope: managementGroup(varManagementGroupIDs.landingZonesConfidentialCorp)
  params: {
    parPolicyAssignmentDefinitionId: varCorpCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varCorpCustomPolicies.libAssignment.properties.description} ${varCorpCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varCorpCustomPolicies.libAssignment.properties.displayName} ${varCorpCustomPolicies.version}'
    parPolicyAssignmentName: take('${varCorpCustomPolicies.libAssignment.name}${varCorpCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Confidential Online Management Group
module modPolicyAssignmentConfidentialOnlineCustom_Confidential '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varConfidentialCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentConfidentialOnlineCustom_Confidential
  scope: managementGroup(varManagementGroupIDs.landingZonesConfidentialOnline)
  params: {
    parPolicyAssignmentDefinitionId: varConfidentialCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varConfidentialCustomPolicies.libAssignment.properties.description} ${varConfidentialCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varConfidentialCustomPolicies.libAssignment.properties.displayName} ${varConfidentialCustomPolicies.version}'
    parPolicyAssignmentName: take('${varConfidentialCustomPolicies.libAssignment.name}${varConfidentialCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Confidential Online Management Group
module modPolicyAssignmentConfidentialOnlineCustom_Online '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varOnlineCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentConfidentialOnlineCustom_Online
  scope: managementGroup(varManagementGroupIDs.landingZonesConfidentialOnline)
  params: {
    parPolicyAssignmentDefinitionId: varOnlineCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varOnlineCustomPolicies.libAssignment.properties.description} ${varOnlineCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varOnlineCustomPolicies.libAssignment.properties.displayName} ${varOnlineCustomPolicies.version}'
    parPolicyAssignmentName: take('${varOnlineCustomPolicies.libAssignment.name}${varOnlineCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Corp Management Group
module modPolicyAssignmentCorpCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varCorpCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentCorpCustom
  scope: managementGroup(varManagementGroupIDs.landingZonesCorp)
  params: {
    parPolicyAssignmentDefinitionId: varOnlineCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varCorpCustomPolicies.libAssignment.properties.description} ${varOnlineCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varCorpCustomPolicies.libAssignment.properties.displayName} ${varOnlineCustomPolicies.version}'
    parPolicyAssignmentName: take('${varCorpCustomPolicies.libAssignment.name}${varOnlineCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Online Management Group
module modPolicyAssignmentOnlineCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varOnlineCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentOnlineCustom
  scope: managementGroup(varManagementGroupIDs.landingZonesOnline)
  params: {
    parPolicyAssignmentDefinitionId: varOnlineCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varOnlineCustomPolicies.libAssignment.properties.description} ${varOnlineCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varOnlineCustomPolicies.libAssignment.properties.displayName} ${varOnlineCustomPolicies.version}'
    parPolicyAssignmentName: take('${varOnlineCustomPolicies.libAssignment.name}${varOnlineCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Platform Management Group
module modPolicyAssignmentPlatformCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varPlatformCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentPlatformCustom
  scope: managementGroup(varManagementGroupIDs.platform)
  params: {
    parPolicyAssignmentDefinitionId: varPlatformCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varPlatformCustomPolicies.libAssignment.properties.description} ${varPlatformCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varPlatformCustomPolicies.libAssignment.properties.displayName} ${varPlatformCustomPolicies.version}'
    parPolicyAssignmentName: take('${varPlatformCustomPolicies.libAssignment.name}${varPlatformCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Platform Connectivity Management Group
module modPolicyAssignmentConnectivityCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varConnectivityCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentConnectivityCustom
  scope: managementGroup(varManagementGroupIDs.platformConnectivity)
  params: {
    parPolicyAssignmentDefinitionId: varConnectivityCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varConnectivityCustomPolicies.libAssignment.properties.description} ${varConnectivityCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varConnectivityCustomPolicies.libAssignment.properties.displayName} ${varConnectivityCustomPolicies.version}'
    parPolicyAssignmentName: take('${varConnectivityCustomPolicies.libAssignment.name}${varConnectivityCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Platform Identity Management Group
module modPolicyAssignmentIdentityCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varIdentityCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentIdentityCustom
  scope: managementGroup(varManagementGroupIDs.platformIdentity)
  params: {
    parPolicyAssignmentDefinitionId: varIdentityCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varIdentityCustomPolicies.libAssignment.properties.description} ${varIdentityCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varIdentityCustomPolicies.libAssignment.properties.displayName} ${varIdentityCustomPolicies.version}'
    parPolicyAssignmentName: take('${varIdentityCustomPolicies.libAssignment.name}${varIdentityCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Platform Management Management Group
module modPolicyAssignmentManagementCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varManagementCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentManagementCustom
  scope: managementGroup(varManagementGroupIDs.platformManagement)
  params: {
    parPolicyAssignmentDefinitionId: varManagementCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varManagementCustomPolicies.libAssignment.properties.description} ${varManagementCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varManagementCustomPolicies.libAssignment.properties.displayName} ${varManagementCustomPolicies.version}'
    parPolicyAssignmentName: take('${varManagementCustomPolicies.libAssignment.name}${varManagementCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Sandbox Management Group
module modPolicyAssignmentSandboxCustom '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSandboxCustomPolicies.libDefinition.properties.policyDefinitions)) {
  name: varModuleDeploymentNames.modPolicyAssignmentSandboxCustom
  scope: managementGroup(varManagementGroupIDs.sandbox)
  params: {
    parPolicyAssignmentDefinitionId: varSandboxCustomPolicies.definitionID
    parPolicyAssignmentDescription: '${varSandboxCustomPolicies.libAssignment.properties.description} ${varSandboxCustomPolicies.version}'
    parPolicyAssignmentDisplayName: '${varSandboxCustomPolicies.libAssignment.properties.displayName} ${varSandboxCustomPolicies.version}'
    parPolicyAssignmentName: take('${varSandboxCustomPolicies.libAssignment.name}${varSandboxCustomPolicies.version}', 24)
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleAssignmentsAdditionalMgs: []
    parPolicyAssignmentIdentityRoleAssignmentsSubs: parIdentityRoleAssignmentsSubs
    parPolicyAssignmentIdentityRoleDefinitionIds: parRoleDefinitionIds
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentNonComplianceMessages: []
    parPolicyAssignmentNotScopes: []
    parTelemetryOptOut: true
  }
}
