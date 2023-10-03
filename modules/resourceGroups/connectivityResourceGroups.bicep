// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : Deploys the resource groups for the hub network and network watcher.
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

// Deploy resource groups for the hub network
module modNetworkingHubResourceGroup '../../dependencies/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep' = {
  name: take('deploy-Hub-Network-Resource-Group-${parTimestamp}', 64)
  params: {
    parLocation: parDeploymentLocation
    parResourceGroupName: '${parDeploymentPrefix}-rg-hub-network-${parDeploymentLocation}${parDeploymentSuffix}'
    parTags: parTags
    parTelemetryOptOut: true
  }
}

//  Deploy resource group for network watcher.
module modNetworkWatcherResourceGroup '../../dependencies/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep' = {
  name: take('deploy-NetworkWatcher-Resource-Group-${parTimestamp}', 64)
  params: {
    parLocation: parDeploymentLocation
    parResourceGroupName: 'NetworkWatcherRG'
    parTags: parTags
    parTelemetryOptOut: true
  }
}

output outConnectivityDeploymentLocation string = parDeploymentLocation
