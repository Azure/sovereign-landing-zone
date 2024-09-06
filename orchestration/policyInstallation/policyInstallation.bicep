// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: It will deploy the ALZ default policies and the SLZ default policy set definitions.
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

@description('Deployment location')
@allowed([
  'australiacentral'
  'australiacentral2'
  'australiaeast'
  'australiasoutheast'
  'brazilsouth'
  'brazilsoutheast'
  'brazilus'
  'canadacentral'
  'canadaeast'
  'centralindia'
  'centralus'
  'centraluseuap'
  'eastasia'
  'eastus'
  'eastus2'
  'eastus2euap'
  'eastusstg'
  'francecentral'
  'francesouth'
  'germanynorth'
  'germanywestcentral'
  'israelcentral'
  'italynorth'
  'japaneast'
  'japanwest'
  'jioindiacentral'
  'jioindiawest'
  'koreacentral'
  'koreasouth'
  'northcentralus'
  'northeurope'
  'norwayeast'
  'norwaywest'
  'polandcentral'
  'qatarcentral'
  'southafricanorth'
  'southafricawest'
  'southcentralus'
  'southcentralusstg'
  'southeastasia'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'switzerlandwest'
  'uaecentral'
  'uaenorth'
  'uksouth'
  'ukwest'
  'westcentralus'
  'westeurope'
  'westindia'
  'westus'
  'westus2'
  'westus3'
])
param parDeploymentLocation string

@description('Set to true to deploy ALZ default policies. DEFAULT: false')
param parDeployAlzDefaultPolicies bool = false

@description('Timestamp with format yyyyMMddTHHmmssZ. Default value set to Execution Timestamp to avoid deployment contention.')
param parTimestamp string = utcNow()

var varManagementGroupId = '${parDeploymentPrefix}${parDeploymentSuffix}'

// Module - create alz default Policy Definitions
module modAlzDefaultPolicyDefinitions '../../dependencies/infra-as-code/bicep/modules/policy/definitions/alz-PolicyDefinitions.bicep' = {
  scope: managementGroup(varManagementGroupId)
  name: take('${parDeploymentPrefix}-polDefs-${parDeploymentLocation}-${parTimestamp}${parDeploymentSuffix}', 64)
}

// Module - create ALZ Policy Set Initiatives
module modAlzPolicySetDefinitions '../../dependencies/infra-as-code/bicep/modules/policy/definitions/alzPolicySetDefinitions.bicep' = if (parDeployAlzDefaultPolicies) {
  scope: managementGroup(varManagementGroupId)
  name: take('${parDeploymentPrefix}-alzPolSetDefs-${parDeploymentLocation}-${parTimestamp}${parDeploymentSuffix}', 64)
  params: {
    parTargetManagementGroupId: varManagementGroupId
  }
  dependsOn: [
    modAlzDefaultPolicyDefinitions
  ]
}

// Module - create default and custom SLZ Policy Set Initiatives
module modDefaultandCustomSlzPolicySetDefinitions '../../dependencies/infra-as-code/bicep/modules/policy/definitions/slz-CustomPolicySetDefinitions.bicep' = {
  scope: managementGroup(varManagementGroupId)
  name: take('${parDeploymentPrefix}-slzPolSetDefs-${parDeploymentLocation}-${parTimestamp}${parDeploymentSuffix}', 64)
}
