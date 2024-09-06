// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : Deploys a resource group for the dashboard resources.
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'subscription'

@description('Location to deploy resources.')
param parDeploymentLocation string

@description('Prefix to use for resource naming.')
param parDeploymentPrefix string

@description('Tags to apply to all created resources.')
param parTags object

@description('Timestamp with format yyyyMMddTHHmmssZ. Default value set to Execution Timestamp to avoid deployment contention.')
param parTimestamp string = utcNow()

@description('Suffix to use for resource naming.')
@maxLength(5)
param parDeploymentSuffix string

// Deploy resource group for dashboard resources
module modDashboardResourceGroup '../../dependencies/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep' = {
  name: take('deploy-Dashboard-Resource-Group-${parTimestamp}', 64)
  params: {
    parLocation: parDeploymentLocation
    parResourceGroupName: '${parDeploymentPrefix}-rg-dashboards-${parDeploymentLocation}${parDeploymentSuffix}'
    parTags: parTags
    parTelemetryOptOut: true
  }
}
