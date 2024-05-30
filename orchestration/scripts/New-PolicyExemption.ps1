# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
    The powershell script creates policy exemptions.
#>
param (
    $parAttendedLogin = $true
)
. ".\Invoke-Helper.ps1"

#variables
$varPolicyExemptionRequiredParams = @('parDeploymentPrefix', 'parDeploymentLocation', 'parPolicyExemptions')
$varPolicyExemptionBicepFilePath = '..\policyExemption\policyExemption.bicep'

<#
.Description
    The function call is to create policy exmeptions for the policies that needs to be exempted
    Parameters:
    parPolicyExemptionParametersFilePath -> path to the parameter file containing required parameters to create policy exemptions
    parParameters -> hash table containing parameter name and value
#>
function Invoke-PolicyExemption {
    param($parPolicyExemptionParametersFilePath, $parParameters)

    if (!$parParameters) {
        $parParameters = Read-ParametersValue($parPolicyExemptionParametersFilePath)
        Get-DonotRetryErrorCodes
    }

    if (($null -eq $parParameters.parPolicyExemptions.value) -or ($parParameters.parPolicyExemptions.value.count -eq 0)) {
        return
    }

    Confirm-Parameters($varPolicyExemptionRequiredParams)
    $varPolicyExemptions = $parParameters.parPolicyExemptions.value
    foreach ($varPolicyExemption in $varPolicyExemptions) {
        New-Exemption $varPolicyExemption
    }
}

<#
.Description
    deploys Policy Exemptions
#>
function New-Exemption {
    param($parPolicyExemption)
    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $varParams = @{
        parDeploymentPrefix               = $parDeploymentPrefix
        parDeploymentSuffix               = $parDeploymentSuffix
        parPolicyAssignmentName           = $parPolicyExemption.parPolicyAssignmentName
        parPolicyAssignmentScopeName      = $parPolicyExemption.parPolicyAssignmentScopeName
        parPolicyExemptionName            = $parPolicyExemption.parPolicyExemptionName
        parPolicyExemptionDisplayName     = $parPolicyExemption.parPolicyExemptionDisplayName
        parDescription                    = $parPolicyExemption.parPolicyExemptionDescription
        parPolicyExemptionManagementGroup = $parPolicyExemption.parPolicyExemptionManagementGroup
        parPolicyDefinitionReferenceIds   = $parPolicyExemption.parPolicyDefinitionReferenceIds
    }

    $varDeploymentName = "deploy-policyExemptions-$vartimeStamp"
    $varLoopCounter = 0;
    $varRetry = $true
    while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        $modDeployPolicyExemption = $null
        try {
            Write-Information ">>> Policy exemption deployment started" -InformationAction Continue

            $modDeployPolicyExemption = New-AzManagementGroupDeployment `
                -Name $varDeploymentName  `
                -Location $parDeploymentLocation `
                -TemplateFile $varPolicyExemptionBicepFilePath `
                -ManagementGroupId $varManagementGroupId `
                -TemplateParameterObject $varParams `
                -WarningAction Ignore

            if (!$modDeployPolicyExemption) {
                Write-Error "`n>>> Error occured in policy exemption" -ErrorAction Stop
            }
            if ($modDeployPolicyExemption.ProvisioningState -eq "Failed") {
                Write-Error "`n Error while executing policy exemption deployment" -ErrorAction Stop
            }

            Write-Information ">>> Policy exemption completed" -InformationAction Continue
            return
        }
        catch {
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            if (!$varRetry) {
                Write-Error ">>> Validation error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            if (!$modDeployPolicyExemption) {
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
                        Write-Error ">>> Error occurred in policy exemption deployment. Please try after addressing the above error." -ErrorAction Stop
                    }
                }
            }
        }
    }
}
