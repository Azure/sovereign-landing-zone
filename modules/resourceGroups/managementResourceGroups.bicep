// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : Deploys a resource group for logging resources.
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'subscription'

@description('Location to deploy resources.')
param parDeploymentLocation string

@description('Prefix to use for resource naming.')
param parDeploymentPrefix string

@description('Suffix to use for resource naming.')
@maxLength(5)
param parDeploymentSuffix string

@description('Tags to apply to all created resources.')
param parTags object

@description('Timestamp with format yyyyMMddTHHmmssZ. Default value set to Execution Timestamp to avoid deployment contention.')
param parTimestamp string = utcNow()

// Deploys resource group
module modAlzLoggingResourceGroup '../../dependencies/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep' = {
  name: take('deploy-Logging-Resource-Group-${parTimestamp}', 64)
  params: {
    parLocation: parDeploymentLocation
    parResourceGroupName: '${parDeploymentPrefix}-rg-logging-${parDeploymentLocation}${parDeploymentSuffix}'
    parTags: parTags
    parTelemetryOptOut: true
  }
}

output outManagementDeploymentLocation string = parDeploymentLocation
