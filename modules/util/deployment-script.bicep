// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

@description('Location for the deployment.')
param parLocation string = resourceGroup().location

@description('Deployment Script Name.')
param parDeploymentScriptName string

@description('Deployment Script')
param parDeploymentScript string

@description('Identity for the deployment script to execute in Azure Container Instance.')
param parDeploymentScriptIdentityId string

@description('Azure CLI Version.  Default: 2.32.0')
param parAzCliVersion string = '2.32.0'

@description('Force Update Tag.  Default:  utcNow()')
param parForceUpdateTag string = utcNow()

@description('Script timeout in ISO 8601 format.  Default is 1 hour.')
param parTimeout string = 'PT1H'

@description('Script retention in ISO 8601 format.  Default is 1 hour.')
param parRetentionInterval string = 'PT1H'

#disable-next-line BCP081
resource resDs 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: parDeploymentScriptName
  location: parLocation
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${parDeploymentScriptIdentityId}': {}
    }
  }
  properties: {
    forceUpdateTag: parForceUpdateTag
    azCliVersion: parAzCliVersion
    retentionInterval: parRetentionInterval
    timeout: parTimeout
    cleanupPreference: 'OnExpiration'
    scriptContent: parDeploymentScript
  }
}
