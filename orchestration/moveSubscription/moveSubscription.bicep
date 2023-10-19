// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This file moves the deployed subscriptions to the correct management groups.
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

@description('Subscription ID for management group.')
param parManagementSubscriptionId string

@description('Subscription ID for identity group.')
param parIdentitySubscriptionId string

@description('Subscription ID for connectivity group.')
param parConnectivitySubscriptionId string

var varManagementGroupId = '${parDeploymentPrefix}${parDeploymentSuffix}'
module modConnectivitySubscriptionPlacement '../../dependencies/infra-as-code/bicep/modules/subscriptionPlacement/subscriptionPlacement.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-Connectivity-Subscription-Placement${parDeploymentSuffix}', 64)
  scope: managementGroup(varManagementGroupId)
  params: {
    parTargetManagementGroupId: '${parDeploymentPrefix}-platform-connectivity${parDeploymentSuffix}'
    parSubscriptionIds: [
      parConnectivitySubscriptionId
    ]
    parTelemetryOptOut: true
  }
}

// Move Subscription to management management group
module modManagementSubscriptionPlacement '../../dependencies/infra-as-code/bicep/modules/subscriptionPlacement/subscriptionPlacement.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-Management-Subscription-Placement', 64)
  scope: managementGroup(varManagementGroupId)
  params: {
    parTargetManagementGroupId: '${parDeploymentPrefix}-platform-management${parDeploymentSuffix}'
    parSubscriptionIds: [
      parManagementSubscriptionId
    ]
    parTelemetryOptOut: true
  }
}

// Move Subscription to identity management group
module modIdentitySubscriptionPlacement '../../dependencies/infra-as-code/bicep/modules/subscriptionPlacement/subscriptionPlacement.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-Identity-Subscription-Placement${parDeploymentSuffix}', 64)
  scope: managementGroup(varManagementGroupId)
  params: {
    parTargetManagementGroupId: '${parDeploymentPrefix}-platform-identity${parDeploymentSuffix}'
    parSubscriptionIds: [
      parIdentitySubscriptionId
    ]
    parTelemetryOptOut: true
  }
}
