# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script serves as the overarching script to deploy SLZ either in its entirety or in a piecemeal manner the below individual modules.

.DESCRIPTION
- Executes the individual modules - bootstrap, platform, compliance, policyexemption, dashboard or all
- bootstrap deploys the management groups and subscriptions
- platform deploys the resource groups in each of the subscriptions along with the networking resources.
- compliance installs the policy sets and assigns them to the individual management groups based on convention
- dashboard deploys the SLZ specific dashboard in the management subscription
- policyexemption exempts the policies defined in parameter parPolicyExemptions.
- policy remediation remediates policies that can be remediated and updates compliance status
#>

using namespace System.Collections

param (
    $parDeployment = $(Read-Host -prompt "Please choose the deployment type from - all, bootstrap, platform, compliance, dashboard, policyexemption, policyremediation"),
    $parParametersFilePath = ".\parameters\sovereignLandingZone.parameters.json",
    $parAttendedLogin = $true
)

$varDeploy = @("all", "bootstrap", "platform", "compliance", "dashboard", "policyexemption", "policyremediation")
if ($parDeployment -notin $varDeploy) {
    Write-Error "Invalid Input. Please choose from the given options" -ErrorAction Stop
}
Write-Information ">>> If you are running this deployment in admin mode and left mouse click in the PowerShell window, a text selection rectangle will appear and deployment will halt. Press the Enter key to continue the deployment." -InformationAction Continue


#reference to individual scripts
. ".\Invoke-Helper.ps1"
. ".\New-Bootstrap.ps1" -parAttendedLogin $parAttendedLogin
. ".\New-Platform.ps1" -parAttendedLogin $parAttendedLogin
. ".\New-PolicyExemption.ps1" -parAttendedLogin $parAttendedLogin
. ".\New-PolicyRemediation.ps1" -parAttendedLogin $parAttendedLogin
. ".\New-Compliance.ps1" -parAttendedLogin $parAttendedLogin
. ".\New-Dashboard.ps1" -parAttendedLogin $parAttendedLogin

$varAllRequiredParams = @('parDeploymentPrefix', 'parTopLevelManagementGroupName', 'parSubscriptionBillingScope', 'parCustomer', 'parDeploymentLocation', 'parAllowedLocations', 'parAllowedLocationsForConfidentialComputing')

# Code execution starts here and is the entry point to the function invocations
Get-DonotRetryErrorCodes
$varParameters = Read-ParametersValue($parParametersFilePath)

if ($parAttendedLogin) {

    $parIsSLZDeployedAtTenantRoot = $true
    if ($null -ne $varParameters.parTopLevelManagementGroupParentId.value) {
        $parIsSLZDeployedAtTenantRoot = $false
    }

    # Confirm Sovereign Landing Zone Prerequisites
    Confirm-Prerequisites $parIsSLZDeployedAtTenantRoot
}

$vartimeStamp = Get-Date -Format "yyyyMMddHHmmss"
$varParameters.add('parDeploymentStartTime', $vartimeStamp)
switch ($parDeployment) {
    'bootstrap' {
        Confirm-Parameters($varBootstrapRequiredParams)
        $modDeployBootstrap = New-Bootstrap $null $varParameters
        if ($modDeployBootstrap) {
            Show-ManagementGroupInfo $varParameters
        }

        return $modDeployBootstrap
    }

    'platform' {
        Confirm-Parameters($varPlatformRequiredParams)
        New-Platform $null $varParameters $null
    }

    'compliance' {
        $parDeployAlzDefaultPolicies = $varParameters.parDeployAlzDefaultPolicies.value
        if ($parDeployAlzDefaultPolicies) {
            $varComplianceRequiredParams = $varComplianceRequiredParams + $varAlzDefaultPolicyRequiredParams
        }

        $varCustomerPolicySets = $varParameters.parCustomerPolicySets.value
        if ($varCustomerPolicySets) {
            $varComplianceRequiredParams = $varComplianceRequiredParams + @("parCustomerPolicySets")
        }

        Confirm-Parameters($varComplianceRequiredParams)
        New-Compliance $null $varParameters $null
    }

    'dashboard' {
        Confirm-Parameters($varDashboardRequiredParams)
        $modDashboard = New-Dashboard $null $varParameters $null
        if ($modDashboard) {
            Show-DashboardInfo $varParameters $null
        }

        return $modDashboard
    }

    'policyexemption' {
        #Run policy exemption
        Invoke-PolicyExemption $null $varParameters
    }

    'policyremediation' {
        Confirm-Parameters($varPolicyRemediationRequiredParams)
        Invoke-PolicyRemediation $null $varParameters
    }

    'all' {
        $varCustomerPolicySets = $varParameters.parCustomerPolicySets.value
        if ($varCustomerPolicySets) {
            $varAllRequiredParams = $varAllRequiredParams + @("parCustomerPolicySets")
        }

        #Validate Parameters
        Confirm-Parameters($varAllRequiredParams)

        #bootstrap
        $modDeployBootstrapOutputs = New-bootstrap $null $varParameters
        if (!$modDeployBootstrapOutputs) {
            Write-Error "Bootstrap deployment script failed." -ErrorAction Stop
        }

        #Platform
        $modDeploySovereignPlatformOutputs = New-Platform $null $varParameters $modDeployBootstrapOutputs
        if (!$modDeploySovereignPlatformOutputs) {
            Write-Error "Platform deployment script failed." -ErrorAction Stop
        }

        #Compliance
        New-Compliance $null $varParameters $modDeploySovereignPlatformOutputs

        #Dashboard
        $modDashboard = New-Dashboard $null $varParameters $modDeployBootstrapOutputs
        if (!$modDashboard) {
            Write-Error "Dashboard deployment script failed." -ErrorAction Stop
        }

        Show-ManagementGroupInfo $varParameters
        Show-DashboardInfo $varParameters $modDeployBootstrapOutputs
    }
}
