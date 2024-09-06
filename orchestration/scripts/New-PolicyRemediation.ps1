# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
    The powershell script creates policy remediations.
#>
param (
    $parAttendedLogin = $true
)
. ".\Invoke-Helper.ps1"

#variables
$varPolicyRemediationRequiredParams = @('parDeploymentPrefix', 'parDeploymentLocation')
$varPolicyRemediationBicepFilePath = '..\policyRemediation\policyRemediation.bicep'

<#
.Description
    The function call is to create policy remediations for the policies that needs to be remediated
    Parameters:
    parPolicyExemptionParametersFilePath -> path to the parameter file containing required parameters to create policy remediations
    parParameters -> hash table containing parameter name and value
#>
function Invoke-PolicyRemediation {
    param($parPolicyRemediationParametersFilePath, $parParameters)

    if (!$parParameters) {
        $parParameters = Read-ParametersValue $parPolicyRemediationParametersFilePath
        Confirm-Parameters $varPolicyRemediationRequiredParams
    }

    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"

    $varPolicyStateList = Get-AzPolicyState -ManagementGroupName  $varManagementGroupId -Filter "(PolicyDefinitionAction eq 'deployifnotexists' or PolicyDefinitionAction eq 'modify') and ComplianceState eq 'NonCompliant'"

    if ( $null -ne $varPolicyStateList) {
        $varPolicyCount = $varPolicyStateList.Count
        Write-Information ">>> Starting policy remediation deployment" -InformationAction Continue

        $varPolicyCounter = 1
        foreach ($varPolicy in $varPolicyStateList) {
            Write-Information "Remediating policy $varPolicyCounter out of $varPolicyCount policies." -InformationAction Continue
            $varPolicyCounter++
            New-Remediation $varPolicy
        }
    }
    else {
        Write-Information "No policies found for remediation." -InformationAction Continue
    }
}

<#
.Description
    Deploys Policy Remediation
#>
function New-Remediation {
    param($parPolicy)

    $varPolicySetDefinitionName = $parPolicy.policySetDefinitionName
    $varGuid = New-Guid
    $varDeploymentName = ("$varGuid" + $varPolicySetDefinitionName)
    $varDeploymentName = $varDeploymentName.Length -ge 64 ? $varDeploymentName.Substring(0, 64) : $varDeploymentName
    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $parPolicyAssignmentScope = $parPolicy.policyAssignmentScope
    $varPattern = "$([regex]::escape($parDeploymentPrefix))(.*)"
    $varRegExResult = $parPolicyAssignmentScope | Select-String -Pattern $varPattern
    $parManagementGroupScope = $varRegExResult.Matches[0].Value
    $parParams = @{
        parDeploymentPrefix            = $parDeploymentPrefix
        parDeploymentSuffix            = $parDeploymentSuffix
        parPolicyRemediationName       = "rem-" + $varDeploymentName
        parPolicyAssignmentId          = $parPolicy.policyAssignmentId
        parPolicyDefinitionReferenceId = $parPolicy.policyDefinitionReferenceId
        parManagementGroupScope        = $parManagementGroupScope
    }

    $parInvokePolicyRemediationSync = $parParameters.parInvokePolicyRemediationSync.value
    $varRetry = $true
    while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        $modDeployPolicyRemediation = $null
        try {
            if ($parInvokePolicyRemediationSync) {
                $varJob = $modDeployPolicyRemediation = New-AzManagementGroupDeployment `
                    -Name $varDeploymentName `
                    -Location $parDeploymentLocation `
                    -TemplateFile $varPolicyRemediationBicepFilePath `
                    -ManagementGroupId $varManagementGroupId `
                    -TemplateParameterObject $parParams `
                    -WarningAction Ignore `
                    -AsJob
                $varJob | Wait-Job


                if (!$modDeployPolicyRemediation) {
                    Write-Error "`n>>> Error occured in policy remediation" -ErrorAction Stop
                }

                if ($modDeployPolicyRemediation.ProvisioningState -eq "Failed") {
                    Write-Error "`n Error while executing policy remediation deployment" -ErrorAction Stop
                }

                Write-Information ">>> Policy remediation $($parParams.parPolicyRemediationName) completed." -InformationAction Continue
                return
            }
            else {
                $modDeployPolicyRemediation = New-AzManagementGroupDeployment `
                    -Name $varDeploymentName `
                    -Location $parDeploymentLocation `
                    -TemplateFile $varPolicyRemediationBicepFilePath `
                    -ManagementGroupId $varManagementGroupId `
                    -TemplateParameterObject $parParams `
                    -WarningAction Ignore `
                    -AsJob

                Write-Information ">>> Policy remediation $($parParams.parPolicyRemediationName) scheduled." -InformationAction Continue
                return
            }
        }
        catch {
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            if (!$varRetry) {
                Write-Error ">>> Validation error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            if (!$modDeployPolicyRemediation) {
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
                        Write-Error ">>> Error occurred in policy remediation deployment. Please try after addressing the above error." -ErrorAction Stop
                    }
                }
            }
        }
    }
}
