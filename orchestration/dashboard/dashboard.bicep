// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This is the main deployment file for the SLZ dashboard. It will deploy the dashboard resource group and the dashboard itself.
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('The prefix that will be added to all resources created by this deployment. DEFAULT: mcfs')
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

@description('The name of the country or agency SLZ is being deployed for. DEFAULT: Country')
param parCustomer string = 'Country'

@description('Tags to be added to deployed resources')
param parTags object = {}

@description('Subscription ID for management group.')
param parManagementSubscriptionId string

var varDashboardResourceGroupName = '${parDeploymentPrefix}-rg-dashboards-${parDeploymentLocation}${parDeploymentSuffix}'

// Deploy dashboard resource group
module modDashboardResourceGroup '../../modules/resourceGroups/dashboardResourceGroups.bicep' = {
  name: take('deploy-Dashboard-Resource-Group-${varDashboardResourceGroupName}', 64)
  scope: subscription(parManagementSubscriptionId)
  params: {
    parDeploymentLocation: parDeploymentLocation
    parDeploymentPrefix: parDeploymentPrefix
    parDeploymentSuffix: parDeploymentSuffix
    parTags: parTags
  }
}

var varDashboardDisplayName = '${parDeploymentPrefix}-Sovereign-Landing-Zone-Dashboard-${parDeploymentLocation}${parDeploymentSuffix}'

// Deploy dashboard
module modDashboard '../../modules/dashboard/dashboard.bicep' = {
  name: take('deploy-${parDeploymentPrefix}-dashboard${parDeploymentSuffix}', 64)
  scope: resourceGroup(parManagementSubscriptionId, varDashboardResourceGroupName)
  params: {
    parCountryOrAgencyName: parCustomer
    parLocation: parDeploymentLocation
    parDashboardName: varDashboardDisplayName
    parTags: parTags
    parDeploymentPrefix: parDeploymentPrefix
    parDeploymentSuffix: parDeploymentSuffix
  }
  dependsOn: [
    modDashboardResourceGroup
  ]
}

output outDashboardResourceGroupName string = varDashboardResourceGroupName
output outDashboardDisplayName string = varDashboardDisplayName
