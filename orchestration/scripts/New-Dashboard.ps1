# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
    The powershell script deploys dashboard as part of SLZ deployment.
#>
param (
    $parAttendedLogin = $true
)
. ".\Invoke-Helper.ps1"

#variables
$varDashboardBicepFilePath = '..\dashboard\dashboard.bicep'
$varDashboardRequiredParams = @('parDeploymentPrefix', 'parDeploymentLocation', 'parManagementSubscriptionId')

<#
.Description
    Creates the SLZ Dashboard under the management group
    Parameters:
    parDashboardParametersFilePath -> path to the parameter file containing required parameters to deploy dashboard
    varParameters -> hash table containing parameter name and value
    modDeployBootstrapOutputs -> hash table containing parameter outputs from bootstrap deployment
#>
function New-Dashboard {
    param($parDashboardParametersFilePath, $parParameters, $parDeployBootstrapOutputs)

    if (!$parParameters -and !$parDeployBootstrapOutputs) {
        $parParameters = Read-ParametersValue($parDashboardParametersFilePath)
        Confirm-Parameters($varDashboardRequiredParams)
        Get-DonotRetryErrorCodes
    }

    if ($parDeployBootstrapOutputs) {
        $varManagementSubscriptionId = $parDeployBootstrapOutputs.outputs.outManagementSubscriptionId.value
    }
    else {
        $varManagementSubscriptionId = $parParameters.parManagementSubscriptionId.value
    }

    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $varDeploymentName = "deploy-dashboard-$vartimeStamp"

    $varParams = @{
        parDeploymentLocation       = $parDeploymentLocation
        parDeploymentPrefix         = $parDeploymentPrefix
        parDeploymentSuffix         = $parDeploymentSuffix
        parManagementSubscriptionId = $varManagementSubscriptionId
        parCustomer                 = $parParameters.parCustomer.value
        parTags                     = Convert-ToHashTable($parParameters.parTags.value)
    }
    $varLoopCounter = 0;
    $varRetry = $true
    while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        $modDeployDashboard = $null
        try {
            Write-Information ">>> Dashboard deployment started" -InformationAction Continue

            $modDeployDashboard = New-AzManagementGroupDeployment `
                -Name $varDeploymentName  `
                -Location $parDeploymentLocation `
                -TemplateFile $varDashboardBicepFilePath `
                -ManagementGroupId $varManagementGroupId `
                -TemplateParameterObject $varParams `
                -WarningAction Ignore

            if (!$modDeployDashboard) {
                $varRetry = $false
                Write-Error "Error while executing dashboard deployment" -ErrorAction Stop
            }
            if ($modDeployDashboard.ProvisioningState -eq "Failed") {
                Write-Error "Error occurred during dashboard deployment." -ErrorAction Stop
            }

            Write-Information  ">>> Dashboard deployment completed `n" -InformationAction Continue

            if (!$parAttendedLogin) {
                Write-Information ">>> Please note: it can take up to 24 hours for the dashboard to reflect the latest data." -InformationAction Continue
            }

            return $modDeployDashboard
        }
        catch {
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            if (!$varRetry) {
                Write-Error ">>> Validation error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            if (!$modDeployDashboard) {
                Write-Error ">>> Error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            else {
                $varDeploymentErrorCodes = Get-FailedDeploymentErrorCodes $varManagementGroupId $varDeploymentName $varManagementGroupDeployment
                if ($null -eq $varDeploymentErrorCodes) {
                    $varRetry = $false
                }
                else {
                    $varLoopCounter++
                    $varRetry = Confirm-Retry $varDeploymentErrorCodes
                    if ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
                        Write-Information ">>> Retrying deployment after waiting for $varRetryWaitTimeTransientErrorRetry secs" -InformationAction Continue
                        Start-Sleep -Seconds $varRetryWaitTimeTransientErrorRetry
                    }
                    else {
                        $varRetry = $false
                        Write-Error ">>> Error occurred in dashboard deployment. Please try after addressing the above error." -ErrorAction Stop
                    }
                }
            }
        }
    }
}
