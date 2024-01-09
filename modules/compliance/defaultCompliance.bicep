// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : This module deploys the policy assignments for the top level management group and the management groups that are children of the top level management group.
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('The top level management group name which is also the prefix used for resources')
param parDeploymentPrefix string

@description('The suffix that will be added to management group suffix name the same way to be added to management group prefix names.')
@maxLength(5)
param parDeploymentSuffix string

@description('The Azure regions where resources are allowed to be deployed by policy.')
param parAllowedLocations array

@description('Locations where confidential resources are available and allowed to be used by workloads.')
param parAllowedLocationsForConfidentialComputing array

@description('Timestamp with format yyyyMMddTHHmmssZ. Default value set to Execution Timestamp to avoid deployment contention.')
param parTimestamp string = utcNow()

@description('Effect type for all policy definitions')
param parPolicyEffect string = 'Deny'

@description('Enforcement mode for all policy assignments.')
param parPolicyAssignmentEnforcementMode string = 'Default'

// **Variables**
// Orchestration Module Variables
var varDeploymentNameWrappers = {
  basePrefix: parDeploymentPrefix
  #disable-next-line no-loc-expr-outside-params //Policies resources are not deployed to a region, like other resources, but the metadata is stored in a region hence requiring this to keep input parameters reduced. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  baseSuffixTenantAndManagementGroup: deployment().location
}

// RBAC Role Definitions Variables - Used For Policy Assignments
var varRbacRoleDefinitionIds = {
  owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  networkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  aksContributor: 'ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'
}

var varModuleDeploymentNames = {
  modPolicyAssignmentIntRootSlzDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-slzDefaults-intRoot-${parTimestamp}', 64)
  modPolicyAssignmentPlatformDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-platformDefaults-${parTimestamp}', 64)
  modPolicyAssignmentSandboxDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-sandboxDefaults-${parTimestamp}', 64)
  modPolicyAssignmentDecommissionedDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-decomDefaults-${parTimestamp}', 64)
  modPolicyAssignmentLandingZoneDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-landingZoneDefaults-${parTimestamp}', 64)
  modPolicyAssignmentCorpDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-corpDefaults-${parTimestamp}', 64)
  modPolicyAssignmentOnlineDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-onlineDefaults-${parTimestamp}', 64)
  modPolicyAssignmentConfidentialCorpDefaults_Confidential: take('${varDeploymentNameWrappers.basePrefix}-polAssi-confCorpDefaults_Confidential-${parTimestamp}', 64)
  modPolicyAssignmentConfidentialCorpDefaults_Corp: take('${varDeploymentNameWrappers.basePrefix}-polAssi-confCorpDefaults_Corp-${parTimestamp}', 64)
  modPolicyAssignmentConfidentialOnlineDefaults_Confidential: take('${varDeploymentNameWrappers.basePrefix}-polAssi-confOnlineDefaults_Confidential-${parTimestamp}', 64)
  modPolicyAssignmentConfidentialOnlineDefaults_Online: take('${varDeploymentNameWrappers.basePrefix}-polAssi-confOnlineDefaults_Online-${parTimestamp}', 64)
  modPolicyAssignmentConnectivityDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-connectivityDefaults-${parTimestamp}', 64)
  modPolicyAssignmentIdentityDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-identityDefaults-${parTimestamp}', 64)
  modPolicyAssignmentManagementDefaults: take('${varDeploymentNameWrappers.basePrefix}-polAssi-managementDefaults-${parTimestamp}', 64)
}

// Policy Assignments Modules Variables
var varSlzGlobalLibDef = loadJsonContent('policySetDefinitions/slzGlobalDefaults.json')
var varSlzGlobalDefaults = {
  definitionID: replace('${varSlzGlobalLibDef.id}.v${varSlzGlobalLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignmnet_deploy_slz_global_defaults.tmpl.json')
  libDefinition: varSlzGlobalLibDef
  version: replace('v${varSlzGlobalLibDef.properties.metadata.version}', '.', '')
}

var varSlzPlatformLibDef = loadJsonContent('policySetDefinitions/slzPlatformDefaults.json')
var varSlzPlatformDefaults = {
  definitionID: replace('${varSlzPlatformLibDef.id}.v${varSlzPlatformLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_platform_defaults.tmpl.json')
  libDefinition: varSlzPlatformLibDef
  version: replace('v${varSlzPlatformLibDef.properties.metadata.version}', '.', '')
}

var varSlzSandboxLibDef = loadJsonContent('policySetDefinitions/slzSandboxDefaults.json')
var varSlzSandboxDefaults = {
  definitionID: replace('${varSlzSandboxLibDef.id}.v${varSlzSandboxLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_sandbox_defaults.tmpl.json')
  libDefinition: varSlzSandboxLibDef
  version: replace('v${varSlzSandboxLibDef.properties.metadata.version}', '.', '')
}

var varSlzDecommissionedLibDef = loadJsonContent('policySetDefinitions/slzDecommissionedDefaults.json')
var varSlzDecommissionedDefaults = {
  definitionID: replace('${varSlzDecommissionedLibDef.id}.v${varSlzDecommissionedLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_decommissioned_defaults.tmpl.json')
  libDefinition: varSlzDecommissionedLibDef
  version: replace('v${varSlzDecommissionedLibDef.properties.metadata.version}', '.', '')
}

var varSlzLandingZoneLibDef = loadJsonContent('policySetDefinitions/slzLandingZoneDefaults.json')
var varSlzLandingZoneDefaults = {
  definitionID: replace('${varSlzLandingZoneLibDef.id}.v${varSlzLandingZoneLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_landing_zones_defaults.tmpl.json')
  libDefinition: varSlzLandingZoneLibDef
  version: replace('v${varSlzLandingZoneLibDef.properties.metadata.version}', '.', '')
}

var varSlzCorpLibDef = loadJsonContent('policySetDefinitions/slzCorpDefaults.json')
var varSlzCorpDefaults = {
  definitionID: replace('${varSlzCorpLibDef.id}.v${varSlzCorpLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_corp_defaults.tmpl.json')
  libDefinition: varSlzCorpLibDef
  version: replace('v${varSlzCorpLibDef.properties.metadata.version}', '.', '')
}

var varSlzOnlineLibDef = loadJsonContent('policySetDefinitions/slzOnlineDefaults.json')
var varSlzOnlineDefaults = {
  definitionID: replace('${varSlzOnlineLibDef.id}.v${varSlzOnlineLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_online_defaults.tmpl.json')
  libDefinition: varSlzOnlineLibDef
  version: replace('v${varSlzOnlineLibDef.properties.metadata.version}', '.', '')
}

var varSlzConfidentialLibDef = loadJsonContent('policySetDefinitions/slzConfidentialDefaults.json')
var varSlzConfidentialDefaults = {
  definitionID: replace('${varSlzConfidentialLibDef.id}.v${varSlzConfidentialLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_confidential_defaults.tmpl.json')
  libDefinition: varSlzConfidentialLibDef
  version: replace('v${varSlzConfidentialLibDef.properties.metadata.version}', '.', '')
}

var varSlzConnectivityLibDef = loadJsonContent('policySetDefinitions/slzConnectivityDefaults.json')
var varSlzConnectivityDefaults = {
  definitionID: replace('${varSlzConnectivityLibDef.id}.v${varSlzConnectivityLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_connectivity_defaults.tmpl.json')
  libDefinition: varSlzConnectivityLibDef
  version: replace('v${varSlzConnectivityLibDef.properties.metadata.version}', '.', '')
}

var varSlzIdentityLibDef = loadJsonContent('policySetDefinitions/slzIdentityDefaults.json')
var varSlzIdentityDefaults = {
  definitionID: replace('${varSlzIdentityLibDef.id}.v${varSlzIdentityLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_identity_defaults.tmpl.json')
  libDefinition: varSlzIdentityLibDef
  version: replace('v${varSlzIdentityLibDef.properties.metadata.version}', '.', '')
}

var varSlzManagementLibDef = loadJsonContent('policySetDefinitions/slzManagementDefaults.json')
var varSlzManagementDefaults = {
  definitionID: replace('${varSlzManagementLibDef.id}.v${varSlzManagementLibDef.properties.metadata.version}', '\${varTargetManagementGroupResourceId}', varTopLevelManagementGroupResourceID)
  libAssignment: loadJsonContent('policyAssignments/policy_assignment_deploy_slz_management_defaults.tmpl.json')
  libDefinition: varSlzManagementLibDef
  version: replace('v${varSlzManagementLibDef.properties.metadata.version}', '.', '')
}

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

// Module - Policy Assignments - Root Management Group
module modPolicyAssignmentSlzGlobalDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzGlobalDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.intRoot)
  name: varModuleDeploymentNames.modPolicyAssignmentIntRootSlzDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzGlobalDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzGlobalDefaults.libAssignment.name}${varSlzGlobalDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzGlobalDefaults.libAssignment.properties.displayName} ${varSlzGlobalDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzGlobalDefaults.libAssignment.properties.description} ${varSlzGlobalDefaults.version}'
    parPolicyAssignmentParameters: varSlzGlobalDefaults.libAssignment.properties.parameters
    parPolicyAssignmentParameterOverrides: {
      listOfAllowedLocations: {
        value: parAllowedLocations
      }
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Decommisioned Management Group
module modPolicyAssignmentSlzDecommissionedDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzDecommissionedDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.decommissioned)
  name: varModuleDeploymentNames.modPolicyAssignmentDecommissionedDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzDecommissionedDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzDecommissionedDefaults.libAssignment.name}${varSlzDecommissionedDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzDecommissionedDefaults.libAssignment.properties.displayName} ${varSlzDecommissionedDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzDecommissionedDefaults.libAssignment.properties.description} ${varSlzDecommissionedDefaults.version}'
    parPolicyAssignmentParameters: varSlzDecommissionedDefaults.libAssignment.properties.parameters
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Management Group
module modPolicyAssignmentSlzLandingZoneDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzLandingZoneDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.landingZones)
  name: varModuleDeploymentNames.modPolicyAssignmentLandingZoneDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzLandingZoneDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzLandingZoneDefaults.libAssignment.name}${varSlzLandingZoneDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzLandingZoneDefaults.libAssignment.properties.displayName} ${varSlzLandingZoneDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzLandingZoneDefaults.libAssignment.properties.description} ${varSlzLandingZoneDefaults.version}'
    parPolicyAssignmentParameters: varSlzLandingZoneDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Confidential Corp Management Group
module modPolicyAssignmentSlzConfidentialCorpDefaults_Confidential '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzConfidentialDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.landingZonesConfidentialCorp)
  name: varModuleDeploymentNames.modPolicyAssignmentConfidentialCorpDefaults_Confidential
  params: {
    parPolicyAssignmentDefinitionId: varSlzConfidentialDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzConfidentialDefaults.libAssignment.name}${varSlzConfidentialDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzConfidentialDefaults.libAssignment.properties.displayName} ${varSlzConfidentialDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzConfidentialDefaults.libAssignment.properties.description} ${varSlzConfidentialDefaults.version}'
    parPolicyAssignmentParameters: varSlzConfidentialDefaults.libAssignment.properties.parameters
    parPolicyAssignmentParameterOverrides: {
      listOfAllowedLocations: {
        value: parAllowedLocationsForConfidentialComputing
      }
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}
// Module - Policy Assignments - Landing Zone Confidential Corp Management Group
module modPolicyAssignmentSlzConfidentialCorpDefaults_Corp '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzCorpDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.landingZonesConfidentialCorp)
  name: varModuleDeploymentNames.modPolicyAssignmentConfidentialCorpDefaults_Corp
  params: {
    parPolicyAssignmentDefinitionId: varSlzCorpDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzCorpDefaults.libAssignment.name}${varSlzCorpDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzCorpDefaults.libAssignment.properties.displayName} ${varSlzCorpDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzCorpDefaults.libAssignment.properties.description} ${varSlzCorpDefaults.version}'
    parPolicyAssignmentParameters: varSlzCorpDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Confidential Online Management Group
module modPolicyAssignmentSlzConfidentialOnlineDefaults_Confidential '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzConfidentialDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.landingZonesConfidentialOnline)
  name: varModuleDeploymentNames.modPolicyAssignmentConfidentialOnlineDefaults_Confidential
  params: {
    parPolicyAssignmentDefinitionId: varSlzConfidentialDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzConfidentialDefaults.libAssignment.name}${varSlzConfidentialDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzConfidentialDefaults.libAssignment.properties.displayName} ${varSlzConfidentialDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzConfidentialDefaults.libAssignment.properties.description} ${varSlzConfidentialDefaults.version}'
    parPolicyAssignmentParameters: varSlzConfidentialDefaults.libAssignment.properties.parameters
    parPolicyAssignmentParameterOverrides: {
      listOfAllowedLocations: {
        value: parAllowedLocationsForConfidentialComputing
      }
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Confidential Online Management Group
module modPolicyAssignmentSlzConfidentialOnlineDefaults_Online '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzOnlineDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.landingZonesConfidentialOnline)
  name: varModuleDeploymentNames.modPolicyAssignmentConfidentialOnlineDefaults_Online
  params: {
    parPolicyAssignmentDefinitionId: varSlzOnlineDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzOnlineDefaults.libAssignment.name}${varSlzOnlineDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzOnlineDefaults.libAssignment.properties.displayName} ${varSlzOnlineDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzOnlineDefaults.libAssignment.properties.description} ${varSlzOnlineDefaults.version}'
    parPolicyAssignmentParameters: varSlzOnlineDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Corp Management Group
module modPolicyAssignmentSlzCorpDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzCorpDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.landingZonesCorp)
  name: varModuleDeploymentNames.modPolicyAssignmentCorpDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzCorpDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzCorpDefaults.libAssignment.name}${varSlzCorpDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzCorpDefaults.libAssignment.properties.displayName} ${varSlzCorpDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzCorpDefaults.libAssignment.properties.description} ${varSlzCorpDefaults.version}'
    parPolicyAssignmentParameters: varSlzCorpDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Landing Zone Online Management Group
module modPolicyAssignmentSlzOnlineDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzOnlineDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.landingZonesOnline)
  name: varModuleDeploymentNames.modPolicyAssignmentOnlineDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzOnlineDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzOnlineDefaults.libAssignment.name}${varSlzOnlineDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzOnlineDefaults.libAssignment.properties.displayName} ${varSlzOnlineDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzOnlineDefaults.libAssignment.properties.description} ${varSlzOnlineDefaults.version}'
    parPolicyAssignmentParameters: varSlzOnlineDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Platform Management Group
module modPolicyAssignmentSlzPlatformDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzPlatformDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.platform)
  name: varModuleDeploymentNames.modPolicyAssignmentPlatformDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzPlatformDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzPlatformDefaults.libAssignment.name}${varSlzPlatformDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzPlatformDefaults.libAssignment.properties.displayName} ${varSlzPlatformDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzPlatformDefaults.libAssignment.properties.description} ${varSlzPlatformDefaults.version}'
    parPolicyAssignmentParameters: varSlzPlatformDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Platform Connectivity Management Group
module modPolicyAssignmentSlzConnectivityDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzConnectivityDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.platformConnectivity)
  name: varModuleDeploymentNames.modPolicyAssignmentConnectivityDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzConnectivityDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzConnectivityDefaults.libAssignment.name}${varSlzConnectivityDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzConnectivityDefaults.libAssignment.properties.displayName} ${varSlzConnectivityDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzConnectivityDefaults.libAssignment.properties.description} ${varSlzConnectivityDefaults.version}'
    parPolicyAssignmentParameters: varSlzConnectivityDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.networkContributor
    ]
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Platform Identity Management Group
module modPolicyAssignmentIdentityDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzIdentityDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.platformIdentity)
  name: varModuleDeploymentNames.modPolicyAssignmentIdentityDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzIdentityDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzIdentityDefaults.libAssignment.name}${varSlzIdentityDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzIdentityDefaults.libAssignment.properties.displayName} ${varSlzIdentityDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzIdentityDefaults.libAssignment.properties.description} ${varSlzIdentityDefaults.version}'
    parPolicyAssignmentParameters: varSlzIdentityDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Platform Management Management Group
module modPolicyAssignmentSlzManagementDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzManagementDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.platformManagement)
  name: varModuleDeploymentNames.modPolicyAssignmentManagementDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzManagementDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzManagementDefaults.libAssignment.name}${varSlzManagementDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzManagementDefaults.libAssignment.properties.displayName} ${varSlzManagementDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzManagementDefaults.libAssignment.properties.description} ${varSlzManagementDefaults.version}'
    parPolicyAssignmentParameters: varSlzManagementDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

// Module - Policy Assignments - Sandbox Management Group
module modPolicyAssignmentSlzSandboxDefaults '../../dependencies/infra-as-code/bicep/modules/policy/assignments/policyAssignmentManagementGroup.bicep' = if (!empty(varSlzSandboxDefaults.libDefinition.properties.policyDefinitions)) {
  scope: managementGroup(varManagementGroupIDs.sandbox)
  name: varModuleDeploymentNames.modPolicyAssignmentSandboxDefaults
  params: {
    parPolicyAssignmentDefinitionId: varSlzSandboxDefaults.definitionID
    parPolicyAssignmentName: take('${varSlzSandboxDefaults.libAssignment.name}${varSlzSandboxDefaults.version}', 24)
    parPolicyAssignmentDisplayName: '${varSlzSandboxDefaults.libAssignment.properties.displayName} ${varSlzSandboxDefaults.version}'
    parPolicyAssignmentDescription: '${varSlzSandboxDefaults.libAssignment.properties.description} ${varSlzSandboxDefaults.version}'
    parPolicyAssignmentParameters: varSlzSandboxDefaults.libAssignment.properties.parameters
    parPolicyAssignmentIdentityType: 'SystemAssigned'
    parPolicyAssignmentIdentityRoleDefinitionIds: [
      varRbacRoleDefinitionIds.owner
    ]
    parPolicyAssignmentParameterOverrides: {
      effect: {
        value: parPolicyEffect
      }
    }
    parPolicyAssignmentEnforcementMode: parPolicyAssignmentEnforcementMode
    parTelemetryOptOut: true
  }
}

output outSlzGlobalVersion string = varSlzGlobalDefaults.version
output outSlzGlobalAssignmentName string = take('${varSlzGlobalDefaults.libAssignment.name}${varSlzGlobalDefaults.version}', 24)
