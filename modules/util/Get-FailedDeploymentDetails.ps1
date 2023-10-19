# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
 The PowerShell scripts aids is generating the logs for the failed deployments.
 This script only retrieves errors when an Azure deployment is created.
 Not all errors will be captured by this script. Specifically those that occur before the deployment is created.

.DESCRIPTION
Execute this script to share the deployment error logs with Microsoft for troubleshooting

#>

param (
    $parDeploymentPrefix = $(Read-Host -prompt "Please enter the deployment prefix used for the SLZ deployment."),
    $parDeploymentSuffix = $(Read-Host -prompt "Please enter the deployment suffix used for the SLZ deployment. Press Enter if no suffix was used for deployment.")
)

<#
.DESCRIPTION
    This function retrieves information about failed Tenant deployments.
    It filters deployments based on provisioning state, deployment name, and generates logs of failed deployment operations.
#>
function Get-FailedTenantDeploymentDetails {
    param ()

    $varFailedTenantDeployments = Get-AzTenantDeployment | Where-Object { $_.ProvisioningState -eq "Failed" -and $_.DeploymentName -like "$parDeploymentPrefix*" }

    if ($null -ne $varFailedTenantDeployments) {
        if (Test-Path tenantLogs.txt) {
            Remove-Item tenantLogs.txt
        }

        $varFailedTenantDeployments | ForEach-Object {
            Get-AzTenantDeploymentOperation -DeploymentName $_.DeploymentName | Where-Object { $_.ProvisioningState -eq "Failed" } *>> tenantLogs.txt
        }
    }

    Write-Information ">>> Tenant deployments log generation completed." -InformationAction Continue
}

<#
.DESCRIPTION
    This function retrieves information about failed Management Group deployments.
    It filters deployments based on provisioning state and generates logs of failed deployment operations.
#>
function Get-FailedManagementGroupDeploymentDetails {
    param ()

    $varFailedMGDeployments = Get-AzManagementGroupDeployment -ManagementGroupId "$parDeploymentPrefix$parDeploymentSuffix" | Where-Object { $_.ProvisioningState -eq "Failed" }

    if ($null -ne $varFailedMGDeployments) {
        if (Test-Path managementgroupLogs.txt) {
            Remove-Item managementgroupLogs.txt
        }

        foreach ($varDeployment in $varFailedMGDeployments) {
            Get-AzManagementGroupDeploymentOperation -ManagementGroupId "$parDeploymentPrefix$parDeploymentSuffix" -DeploymentName $varDeployment.DeploymentName | Where-Object { $_.ProvisioningState -eq "Failed" } *>> managementgroupLogs.txt
        }
    }

    Write-Information ">>> Management group deployments log generation completed." -InformationAction Continue
}

Write-Information ">>> Initiating a login" -InformationAction Continue
Connect-AzAccount

Get-FailedTenantDeploymentDetails
Get-FailedManagementGroupDeploymentDetails
