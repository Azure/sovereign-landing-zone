# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
    The powershell script deploys bootstrap as part of SLZ deployment.
#>

param (
    $parAttendedLogin = $true
)

. ".\Invoke-Helper.ps1"

#variables
$varBootstrapBicepFilePath = '..\bootstrap\bootstrap.bicep'
$varBootstrapScopeEscapeBicepFilePath = '..\bootstrap\bootstrapScopeEscape.bicep'
$varBootstrapRequiredParams = @('parDeploymentPrefix', 'parTopLevelManagementGroupName', 'parSubscriptionBillingScope', 'parDeploymentLocation')

<#
.Description
    Creates the management group hierarchy and subscriptions at tenant level
    Parameters:
    parBootstrapParametersFilePath -> path to the parameter file containing required parameters to deploy bootstrap
    parParameters -> hash table containing parameter name and value
#>
function New-Bootstrap {
    param($parBootstrapParametersFilePath, $parParameters)

    if (!$parParameters) {
        $parParameters = Read-ParametersValue($parBootstrapParametersFilePath)
        Confirm-Parameters($varBootstrapRequiredParams)
        Get-DonotRetryErrorCodes
    }

    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $varDeploymentName = "deploy-bootstrap-$vartimeStamp"
    $varParams = @{
        parDeploymentPrefix                = $parDeploymentPrefix
        parDeploymentSuffix                = $parDeploymentSuffix
        parSubscriptionBillingScope        = $parParameters.parSubscriptionBillingScope.value
        parTopLevelManagementGroupName     = $parParameters.parTopLevelManagementGroupName.value
        parManagementSubscriptionId        = $parParameters.parManagementSubscriptionId.value
        parIdentitySubscriptionId          = $parParameters.parIdentitySubscriptionId.value
        parConnectivitySubscriptionId      = $parParameters.parConnectivitySubscriptionId.value
        parLandingZoneMgChildren           = Convert-ToArray($parParameters.parLandingZoneMgChildren.value)
        parTopLevelManagementGroupParentId = $parParameters.parTopLevelManagementGroupParentId.value
        parTags                            = Convert-ToHashTable($parParameters.parTags.value)
    }
    $varLoopCounter = 0;
    $varRetry = $true
    $varTopLevelManagementGroupParentName = $null
    while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        $modDeployBootstrap = $null
        try {
            Write-Information ">>> Bootstrap deployment started" -InformationAction Continue

            if ([string]::IsNullOrEmpty($varParams.parTopLevelManagementGroupParentId)) {
                $modDeployBootstrap = New-AzTenantDeployment `
                    -Name $varDeploymentName `
                    -Location $parDeploymentLocation `
                    -TemplateFile $varBootstrapBicepFilePath `
                    -TemplateParameterObject $varParams `
                    -WarningAction Ignore
            }
            else {
                if ($varParams.parTopLevelManagementGroupParentId.ToLower() -like "/providers/microsoft.management/managementGroups/*") {
                    $varTopLevelManagementGroupParentName = ($varParams.parTopLevelManagementGroupParentId -split '/')[-1]
                }
                else {
                    $varRetry = $false
                    Write-Error "The value for parTopLevelManagementGroupParentId parameter has incorrect format. Please refer the sample value in the parameter file for more details." -ErrorAction Stop
                }

                $modDeployBootstrap = New-AzManagementGroupDeployment `
                    -Name $varDeploymentName `
                    -ManagementGroupId $varTopLevelManagementGroupParentName `
                    -Location $parDeploymentLocation `
                    -TemplateFile $varBootstrapScopeEscapeBicepFilePath `
                    -TemplateParameterObject $varParams `
                    -WarningAction Ignore
            }

            if (!$modDeployBootstrap) {
                $varRetry = $false
                Write-Error "Error while executing bootstrap deployment command" -ErrorAction Stop
            }

            if ($modDeployBootstrap.ProvisioningState -eq "Failed") {
                Write-Error "Error occurred during bootstrap deployment." -ErrorAction Stop
            }

            Write-Information ">>> Bootstrap deployment completed`n" -InformationAction Continue
            # Have to register Microsoft.Network early to avoid error "Subscription not registered with NRP"
            # caused by registration delay that occurs during deployments.
            $varConnectivitySubscriptionId = $modDeployBootstrap.Outputs.outConnectivitySubscriptionId.Value
            Write-Information "Registering Microsoft.Network resource provider for subscription id: $varConnectivitySubscriptionId...." -InformationAction Continue
            Set-AzContext -Subscription "$varConnectivitySubscriptionId"
            Register-ResourceProvider "Microsoft.Network"
            #Move customer provided subscriptions to the slz management group
            if ($parParameters.parConnectivitySubscriptionId.value -or $parParameters.parIdentitySubscriptionId.value -or $parParameters.parManagementSubscriptionId.value){
                Move-Subscription $varParameters $modDeployBootstrap
            }
            # update parameters
            Out-DeploymentParameters "bootstrap" $modDeployBootstrap $varManagementGroupId $parParameters

            return $modDeployBootstrap
        }
        catch {
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            if (!$varRetry) {
                Write-Error ">>> Validation error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            if (!$modDeployBootstrap) {
                Write-Error ">>> Error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            else {
                if ([string]::IsNullOrEmpty($varParams.parTopLevelManagementGroupParentId)) {
                    $varDeploymentErrorCodes = Get-FailedDeploymentErrorCodes $varManagementGroupId $varDeploymentName $varTenantDeployment
                }
                else {
                    $varDeploymentErrorCodes = Get-FailedDeploymentErrorCodes $varTopLevelManagementGroupParentName $varDeploymentName $varManagementGroupDeployment
                }

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
                        Write-Error ">>> Error occurred in bootstrap deployment. Please try after addressing the above error." -ErrorAction Stop
                    }
                }
            }
        }
    }
}
