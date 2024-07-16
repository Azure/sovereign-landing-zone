# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
    The powershell script deploys policies as part of SLZ deployment.
#>
param (
    $parAttendedLogin = $true
)
. ".\Invoke-Helper.ps1"
. ".\New-PolicyExemption.ps1" -parAttendedLogin $parAttendedLogin
. ".\New-PolicyRemediation.ps1" -parAttendedLogin $parAttendedLogin

#variables
$varDefaultComplianceBicepFilePath = '..\defaultCompliance\defaultCompliance.bicep'
$varCustomComplianceBicepFilePath = '..\customCompliance\customCompliance.bicep'
$varPolicyInstallationBicepFilePath = '..\policyInstallation\policyInstallation.bicep'
$varComplianceRequiredParams = @('parDeploymentPrefix', 'parAllowedLocations', 'parAllowedLocationsForConfidentialComputing', 'parDeploymentLocation')
$varAlzDefaultPolicyRequiredParams = @('parLogAnalyticsWorkspaceId', 'parAutomationAccountName', 'parPrivateDnsResourceGroupId')
<#
.Description
    Deletes the custom and default policy assignments for each of the SLZ management groups.
#>
function Get-PolicyAssignmentsandExemptions {
    param ($parParameters)

    $varLoopCounter = 0;
    while ($varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        try {
            Write-Information ">>> Verifying policy assignments are present in SLZ" -InformationAction Continue
            $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
            $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
            $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
            $varScope = "/providers/Microsoft.Management/managementGroups/" + $varManagementGroupId
            $varPolicyAssignmentsList = Get-AzPolicyAssignment -Scope $varScope -WarningAction Ignore
            if ($null -eq $varPolicyAssignmentsList) {
                Write-Information ">>> Policy assignments are not deployed in the env." -InformationAction Continue
                return
            }

            Write-Information ">>> Policy assignments found. Fetching policy set definition files for version check" -InformationAction Continue
            $varPolicySetDefinitionDict = Get-PolicySetDefinitionVersion

            Write-Information ">>> For deployed SLZ Policy Sets, checking if there's a version update" -InformationAction Continue
            [System.Collections.ArrayList]$varListOfUpdatedPolicySetDefinitionIds = @()

            if (Confirm-AzResourceVersion) {
                $varPolicySetDefinitions = Get-AzPolicySetDefinition -ManagementGroupName $varManagementGroupId -BackwardCompatible -WarningAction Ignore
            }
            else {
                $varPolicySetDefinitions = Get-AzPolicySetDefinition -ManagementGroupName $varManagementGroupId -WarningAction Ignore
            }
            foreach ($varUpcomingPolicySet in $varPolicySetDefinitionDict.GetEnumerator()) {
                $varPolicySetDefinition = $varPolicySetDefinitions | Where-Object { $_.Name -eq $varUpcomingPolicySet.Key -or $_.Name -match "$($varUpcomingPolicySet.Key).v" }
                $varPolicySetDefinitionVersion = $varUpcomingPolicySet.Value
                foreach ($varPolicyset in $varPolicySetDefinition) {
                    $varDeployedPolicySetDefinitonVersion = $varPolicyset.Properties.Metadata.version
                    if ($varPolicySetDefinitionVersion -gt $varDeployedPolicySetDefinitonVersion) {
                        $varListOfUpdatedPolicySetDefinitionIds.add($varPolicyset.Name) >> $null
                    }
                }
            }

            return $varListOfUpdatedPolicySetDefinitionIds
        }
        catch {
            $varLoopCounter++
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            Write-Error "$varException \n $varErrorDetails \n $varTrace" -ErrorAction Continue

            if ($varLoopCounter -eq $varMaxTransientErrorRetryAttempts) {
                Write-Information ">>> Maximum number of retry attempts reached. Cancelling deployment." -InformationAction Continue
                Write-Error ">>> Error ocurred during getting policy assignment. Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
        }
    }
}

<#
.Description
    Deletes the custom and default policy assignments for each of the SLZ management groups.
#>
function Remove-PolicyAssignmentsandExemptions {
    param ($varListOfUpdatedPolicySetDefinitionIds)

    $varLoopCounter = 0;
    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"

    while ($varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        try {
            Write-Information ">>> Cleaning old policy assignments in SLZ" -InformationAction Continue
            if (!$varListOfUpdatedPolicySetDefinitionIds) {
                Write-Information ">>> No updates to policy set definiton id version." -InformationAction Continue
            }
            else {
                Write-Information ">>> Policy assignment and exemption clean up started" -InformationAction Continue
                $varManagementGroupNames = $varManagementGroupId, "decommissioned", "landingzones", "landingzones-confidential-corp", "landingzones-confidential-online", "landingzones-corp", "landingzones-online", "platform", "platform-connectivity", "platform-identity", "platform-management", "sandbox"
                $varManagementGroupNames | ForEach-Object {
                    if ($_ -eq $varManagementGroupId) {
                        $varScope = "/providers/Microsoft.Management/managementGroups/" + $varManagementGroupId
                    }
                    else {
                        $varScope = "/providers/Microsoft.Management/managementGroups/" + $parDeploymentPrefix + "-" + $_ + $parDeploymentSuffix
                    }

                    [System.Collections.ArrayList]$varListOfUpdatedPolicyAssignmentNames = @()
                    $varAssignments = Get-AzPolicyAssignment -Scope $varScope -WarningAction Ignore
                    if ($null -ne $varAssignments) {
                        $varAssignments | ForEach-Object {
                            $varPolicyDefinitionId = $_.Properties.PolicyDefinitionId.Substring($_.Properties.PolicyDefinitionId.LastIndexOf('/') + 1)
                            if ($varListOfUpdatedPolicySetDefinitionIds.Contains($varPolicyDefinitionId)) {
                                $varListOfUpdatedPolicyAssignmentNames.Add($_.name) >> $null
                                Remove-AzPolicyAssignment -Scope $varScope -Name $_.name -WarningAction Ignore >> $null
                            }
                        }
                    }

                    $varExemptions = Get-AzPolicyExemption -Scope $varScope -WarningAction Ignore
                    if ($null -ne $varExemptions) {
                        $varExemptions | ForEach-Object {
                            if ($varListOfUpdatedPolicyAssignmentNames.Contains($_.name)) {
                                Remove-AzPolicyExemption -Scope $varScope -Name $_.name -WarningAction Ignore -Confirm:$false >> $null
                            }
                        }
                    }
                }

                Write-Information ">>> Policy assignment and exemption clean up completed. Executing the next steps after waiting for $varRetryWaitTimeTransientErrorRetry seconds." -InformationAction Continue
            }

            return
        }
        catch {
            $varLoopCounter++
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            Write-Error "$varException \n $varErrorDetails \n $varTrace" -ErrorAction Continue

            if ($varLoopCounter -eq $varMaxTransientErrorRetryAttempts) {
                Write-Information ">>> Maximum number of retry attempts reached. Cancelling deployment." -InformationAction Continue
                Write-Error ">>> An error occurred during Remove-PolicyAssignmentsandExemptions. Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
        }
    }
}

<#
.Description
    Installs the custom and default policy sets at the root of the SLZ management group.
#>
function New-InstallPolicySets {
    param ()
    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $varDeploymentName = "deploy-policyinstallation-$vartimeStamp"
    $varParams = @{
        parDeploymentPrefix         = $parDeploymentPrefix
        parDeploymentSuffix         = $parDeploymentSuffix
        parDeploymentLocation       = $parDeploymentLocation
        parDeployAlzDefaultPolicies = $parParameters.parDeployAlzDefaultPolicies.value
    }
    $varLoopCounter = 0;
    $varRetry = $true
    while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        $modDeployPolicyInstallation = $null
        try {
            Write-Information ">>> Policy Installation started" -InformationAction Continue
            $modDeployPolicyInstallation = New-AzManagementGroupDeployment `
                -Name  $varDeploymentName `
                -Location $parDeploymentLocation `
                -TemplateFile $varPolicyInstallationBicepFilePath `
                -ManagementGroupId $varManagementGroupId `
                -TemplateParameterObject $varParams `
                -WarningAction Ignore

            if (!$modDeployPolicyInstallation) {
                $varRetry = $false
                Write-Error "`n Error while executing policy installation" -ErrorAction Stop
            }
            if ($modDeployPolicyInstallation.ProvisioningState -eq "Failed") {
                Write-Error "`n Error while executing policy installation" -ErrorAction Stop
            }

            Write-Information ">>> Policy installation completed" -InformationAction Continue
            return
        }
        catch {
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            if (!$varRetry) {
                Write-Error ">>> Validation error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            if (!$modDeployPolicyInstallation) {
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
                        Write-Error ">>> Error occurred in install policy sets. Please try after addressing the above error." -ErrorAction Stop
                    }
                }
            }
        }
    }
}



<#
.Description
    Assigns the custom policy sets to the SLZ management groups based on convention
#>
function New-CustomCompliance {
    param()
    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $varCustomerPolicySets = Convert-ToArray($parParameters.parCustomerPolicySets.value)

    $varCustomerPolicySets.foreach({
            if ($null -ne $_.policyParameterFilePath -and $_.policyParameterFilePath -ne "") {
                $_.policyAssignmentParameters = (Get-Content -Path $_.policyParameterFilePath -Raw) -replace '\r?\n', ''
            }
            else {
                $_.policyAssignmentParameters = '{}'
            }
        })

    $varParams = @{
        parDeploymentPrefix                = $parDeploymentPrefix
        parDeploymentSuffix                = $parDeploymentSuffix
        parRequireOwnerRolePermission      = $parParameters.parRequireOwnerRolePermission.value
        parCustomerPolicySets              = $varCustomerPolicySets
        parPolicyAssignmentEnforcementMode = $parParameters.parPolicyAssignmentEnforcementMode.value
    }

    $varDeploymentName = "deploy-customcompliance-$vartimeStamp"
    $varCustomPolicySetExists = Confirm-PolicySetExists $varManagementGroupId "custom"
    if ($varCustomPolicySetExists -eq $true) {
        $varLoopCounter = 0;
        $varRetry = $true
        while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
            $modDeployCustomCompliance = $null
            try {
                Write-Information ">>> Custom compliance deployment started" -InformationAction Continue

                $modDeployCustomCompliance = New-AzManagementGroupDeployment `
                    -Name $varDeploymentName  `
                    -Location $parDeploymentLocation `
                    -TemplateFile $varCustomComplianceBicepFilePath `
                    -ManagementGroupId $varManagementGroupId `
                    -TemplateParameterObject $varParams `
                    -WarningAction Ignore

                if (!$modDeployCustomCompliance) {
                    Write-Error "`n>>> Error occurred in custom policy set assignment." -ErrorAction Stop
                }
                if ($modDeployCustomCompliance.ProvisioningState -eq "Failed") {
                    Write-Error "Error occurred during custom compliance deployment." -ErrorAction Stop
                }

                Write-Information ">>> Custom compliance completed `n" -InformationAction Continue
                return $modDeployCustomCompliance
            }
            catch {
                $varException = $_.Exception
                $varErrorDetails = $_.ErrorDetails
                $varTrace = $_.ScriptStackTrace
                if (!$varRetry) {
                    Write-Error ">>> Validation error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
                }
                if (!$modDeployCustomCompliance) {
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
                            Write-Error ">>> Error occurred in custom compliance deployment. Please try after addressing the above error." -ErrorAction Stop
                        }
                    }
                }
            }
        }
    }
    else {
        Write-Error ">>> The required custom policy sets were not found. Please try again after some time." -ErrorAction Stop
    }
}

<#
.Description
    Assigns the default policy sets to the SLZ management groups based on convention
#>
function New-DefaultCompliance {
    param($parDdosProtectionResourceId, $parLogAnalyticsWorkspaceId, $parAutomationAccountName, $parPrivateDnsResourceGroupId)
    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $parAllowedLocations = $parParameters.parAllowedLocations.value
    $parAllowedLocationsForConfidentialComputing = $parParameters.parAllowedLocationsForConfidentialComputing.value

    if ($parAllowedLocations -is [string]) {
        $parAllowedLocations = -split $parAllowedLocations
    }

    if ($parAllowedLocationsForConfidentialComputing -is [string]) {
        $parAllowedLocationsForConfidentialComputing = -split $parAllowedLocationsForConfidentialComputing
    }

    $varParams = @{
        parDeploymentPrefix                                  = $parDeploymentPrefix
        parDeploymentSuffix                                  = $parDeploymentSuffix
        parAllowedLocations                                  = $parAllowedLocations
        parAllowedLocationsForConfidentialComputing          = $parAllowedLocationsForConfidentialComputing
        parDeployAlzDefaultPolicies                          = $parParameters.parDeployAlzDefaultPolicies.value
        parDdosPlanResourceId                                = $parDdosProtectionResourceId
        parLogAnalyticsWorkspaceId                           = $parLogAnalyticsWorkspaceId
        parAutomationAccountName                             = $parAutomationAccountName
        parLogAnalyticsWorkSpaceAndAutomationAccountLocation = $parDeploymentLocation
        parPrivateDnsResourceGroupId                         = $parPrivateDnsResourceGroupId
        parLogAnalyticsWorkspaceLogRetentionInDays           = ($parParameters.parLogRetentionInDays.value).ToString()
        parMsDefenderForCloudEmailSecurityContact            = $parParameters.parMsDefenderForCloudEmailSecurityContact.value
        parPolicyEffect                                      = $parParameters.parPolicyEffect.value
        parPolicyAssignmentEnforcementMode                   = $parParameters.parPolicyAssignmentEnforcementMode.value
        parExcludedALZPolicyAssignments                      = Get-ALZPolicyAssignmentNames
    }

    $varDeploymentName = "deploy-defaultcompliance-$vartimeStamp"
    $varRetry = $true
    while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        $modDeployDefaultCompliance = $null;
        try {
            Write-Information ">>> Default compliance deployment started" -InformationAction Continue

            $modDeployDefaultCompliance = New-AzManagementGroupDeployment `
                -Name $varDeploymentName `
                -Location $parDeploymentLocation `
                -TemplateFile $varDefaultComplianceBicepFilePath `
                -ManagementGroupId $varManagementGroupId `
                -TemplateParameterObject $varParams `
                -WarningAction Ignore

            if (!$modDeployDefaultCompliance) {
                $varRetry = $false
                Write-Error "`n>>> Error occurred in default policy set assignment." -ErrorAction Stop
            }

            if ($modDeployDefaultCompliance.ProvisioningState -eq "Failed") {
                Write-Error "Error occurred during default compliance deployment." -ErrorAction Stop
            }

            Write-Information ">>> Default compliance completed" -InformationAction Continue
            return $modDeployDefaultCompliance
        }
        catch {
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            if (!$varRetry) {
                Write-Error ">>> Validation error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            if (!$modDeployDefaultCompliance) {
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
                        Write-Error ">>> Error occurred in default compliance deployment. Please try after addressing the above error." -ErrorAction Stop
                    }
                }
            }
        }
    }
    else {
        Write-Error ">>> The required default policy sets were not found. Please try again after some time." -ErrorAction Stop
        return $false
    }
}

<#
.Description
    Get the list of all ALZ Policy Assignments.
#>
function Get-ALZPolicyAssignmentNames {

    # The SLZ baseline policies
    $varSLZBaseline = @(
        "/providers/Microsoft.Authorization/policySetDefinitions/03de05a4-c324-4ccd-882f-a814ea8ab9ea",
        "/providers/Microsoft.Authorization/policySetDefinitions/c1cbff38-87c0-4b9f-9f70-035c7a3b5523"
        )

    try {
        $varALZPolicyAssignmentsRootPath = "../../dependencies/infra-as-code/bicep/modules/policy/assignments/lib/policy_assignments"

        $varPolicySetAssignmentFiles = Get-ChildItem -Path "$varALZPolicyAssignmentsRootPath/*.json"
        $varObjArray = @()
        foreach ($varFile in $varPolicySetAssignmentFiles) {
            Write-Information "Processing $varFile.Name" -InformationAction Continue

            $varFilePath = $varALZPolicyAssignmentsRootPath + "/" + $varFile.Name
            $varJsonContent = Get-Content $varFilePath | ConvertFrom-Json
            if ($null -ne $varJsonContent -and !$varSLZBaseline.contains($varJsonContent.properties.policyDefinitionId)) {
                $varObjArray += $varJsonContent.Name
            }
        }

        return , $varObjArray
    }
    catch {
        $varTrace = $_.ScriptStackTrace
        Write-Error ">>> Error occurred during executing Get-ALZPolicyAssignmentNames. Please try after addressing the below error: $_ $varTrace" -ErrorAction Stop
    }
}

<#
.Description
    On demand policy evaluation
#>
function Invoke-PolicyEvaluation {
    param()
    if ($parAttendedLogin) {
        Write-Information ">>> In order to reflect the latest compliance data of policies, you will now be logged out of Azure and asked to re-login. Please authenticate when prompted." -InformationAction Continue
        Disconnect-AzAccount
        Connect-AzAccount
    }
    else {
        return
    }
    Write-Information ">>> Trigerring policy scan." -InformationAction Continue
    try {
        $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
        $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
        $varSubscriptions = $null;
        if (!$parParameters.parIdentitySubscriptionId.value -and !$parParameters.parConnectivitySubscriptionId.value -and !$parParameters.parManagementSubscriptionId.value) {
            $varSubscriptions = Get-AzSubscription | Where-Object { $_.Name -like "$parDeploymentPrefix*$parDeploymentSuffix" -and $_.State -eq 'Enabled' }
        }
        else {
            $varIdentitySubscriptionId = $parParameters.parIdentitySubscriptionId.value
            $parConnectivitySubscriptionId = $parParameters.parConnectivitySubscriptionId.value
            $varManagementSubscriptionId = $parParameters.parManagementSubscriptionId.value
            $varSubscriptions = Get-AzSubscription | Where-Object { ($_.Id -eq "$varIdentitySubscriptionId" -or $_.Id -eq "$parConnectivitySubscriptionId" -or $_.Id -eq "$varManagementSubscriptionId") -and $_.State -eq 'Enabled' }
        }

        if (!$varSubscriptions) {
            Write-Error "Error while executing subscription list command" -ErrorAction Stop
        }
        $varSubscriptionCount = $varSubscriptions.count
        if ($varSubscriptionCount -eq 0) {
            Write-Information ">>> No subscriptions found" -InformationAction Continue
        }

        $parInvokePolicyScanSync = $parParameters.parInvokePolicyScanSync.value
        if ($parInvokePolicyScanSync) {
            Write-Information ">>> Policy scan will be executed in synchronous mode. The process may take up to an hour." -InformationAction Continue
        }
        else {
            Write-Information ">>> Policy scan will be executed in asynchronous mode." -InformationAction Continue
        }

        $varSubscriptionCounter = 1
        foreach ($varSubscription in $varSubscriptions) {
            $varSubscriptionId = $varSubscription.Id;
            Write-Information "Executing policy evaluation scan for subscription id: $varSubscriptionId . Processing  $varSubscriptionCounter out of $varSubscriptionCount. " -InformationAction Continue
            $varSubscriptionCounter++

            # This is not logic requirement, but have to register Microsoft.Network early to avoid Subscription XXXXX-XXXXX-XXXXXXX-XXXXXXX is not registered with NRP because of registration delay.
            Write-Information ">>> Registering Microsoft.Network resource provider for existing subscriptions..." -InformationAction Continue
            Set-AzContext -Subscription "$varSubscriptionId"
            Register-AzResourceProvider -ProviderNamespace Microsoft.Network

            Write-Information "Registering policy insights resource provider for subscription id: $varSubscriptionId (May take upto 2 minutes)...." -InformationAction Continue
            Set-AZContext -Subscription $varSubscriptionId
            $varJob = Register-AzResourceProvider `
                -ProviderNamespace 'Microsoft.PolicyInsights' `
                -AsJob
            $varJob | Wait-Job

            if ($parInvokePolicyScanSync) {
                $varJob = Start-AzPolicyComplianceScan -AsJob
                $varJob | Wait-Job
            }
            else {
                Start-AzPolicyComplianceScan -AsJob
            }
        }
        Write-Information "Policy scan completed." -InformationAction Continue
    }
    catch {
        $_
        Write-Error ">>> Error occurred during policy evaluation. Please try after addressing the above error." -ErrorAction Stop
    }
}

<#
.Description
    Generates the Policies.
#>
function Invoke-PolicyGeneration {

    try {

        Write-Information ">>> Initiating Policy generation script" -InformationAction Continue

        $varInvokeSLZCustomPolicy = '.\Invoke-SlzCustomPolicyToBicep.ps1'
        & $varInvokeSLZCustomPolicy -parAttendedLogin $parAttendedLogin -ErrorAction Stop

        Write-Information ">>> Policy generation complete" -InformationAction Continue
        return
    }
    catch {
        $varTrace = $_.ScriptStackTrace
        Write-Error ">>> Error occurred during executing policy generation script. Please try after addressing the below error: $_ $varTrace" -ErrorAction Stop
    }
}

<#
.Description
    Gets the default and custom policy set definition name and versions.
#>
function Get-PolicySetDefinitionVersion {
    $varTargetDirectories = "../../custom/policies/definitions"
    $varPolicySetDefinitionDict = @{}
    foreach ($varDirectory in $varTargetDirectories) {
        $varSlzPolicySetDefinitionFiles = Get-ChildItem -Path "$varDirectory/*.json"
        foreach ($varFile in $varSlzPolicySetDefinitionFiles) {
            $varFileName = $varFile.Name
            Write-Debug "Processing $varFileName"

            $varFilePath = $varDirectory + "/" + $varFileName
            $varJsonContent = Get-Content $varFilePath | ConvertFrom-Json
            if ($varJsonContent.properties.policyDefinitions.Length -gt 0 -and $varJsonContent.name) {
                $varPolicySetDefinitionDict[$varJsonContent.name] = $varJsonContent.properties.metadata.version
            }
            else {
                Write-Information ">>> $varFileName not checked for version" -InformationAction Continue
            }
        }
        return $varPolicySetDefinitionDict
    }

}

<#
.Description
    Creates the management group hierarchy and subscriptions at tenant level
    Parameters:
    parComplianceParametersFilePath -> path to the parameter file containing required parameters to deploy policies
    varParameters -> hash table containing parameter name and value
    modDeploySovereignPlatformOutputs -> hash table containing parameter outputs from platform deployment
#>
function New-Compliance {
    param($parComplianceParametersFilePath, $parParameters, $parDeploySovereignPlatformOutputs)

    if (!$parParameters -and !$parDeploySovereignPlatformOutputs) {
        $parParameters = Read-ParametersValue($parComplianceParametersFilePath)
        $parDeployAlzDefaultPolicies = $parParameters.parDeployAlzDefaultPolicies.value
        if ($parDeployAlzDefaultPolicies) {
            $varComplianceRequiredParams = $varComplianceRequiredParams + $varAlzDefaultPolicyRequiredParams
        }
        Confirm-Parameters($varComplianceRequiredParams)
        Get-DonotRetryErrorCodes
    }

    if ($parDeploySovereignPlatformOutputs) {
        $varDeployHubNetwork = $parParameters.parDeployHubNetwork.value
        $varDeployDdosProtection = $parParameters.parDeployDdosProtection.value
        if ($varDeployHubNetwork -and $varDeployDdosProtection) {
            $varDdosProtectionResourceId = $parDeploySovereignPlatformOutputs.outputs.outDdosProtectionResourceId.value
        }
        else {
            $varDdosProtectionResourceId = $parParameters.parDdosProtectionResourceId.value
        }

        $varDeployLogAnalyticsWorkspace = $parParameters.parDeployLogAnalyticsWorkspace.value
        if ($varDeployLogAnalyticsWorkspace) {
            $parLogAnalyticsWorkspaceId = $parDeploySovereignPlatformOutputs.outputs.outLogAnalyticsWorkspaceId.value
        }
        else {
            $parLogAnalyticsWorkspaceId = $parParameters.parLogAnalyticsWorkspaceId.value
        }

        $varAutomationAccountName = $parDeploySovereignPlatformOutputs.outputs.outAutomationAccountName.value
        $varPrivateDnsZones = $parDeploySovereignPlatformOutputs.outputs.outPrivateDNSZones.value
        $varPrivateDnsResourceGroupId = Get-PrivateDnsResourceGroupId $varPrivateDnsZones $parParameters
    }
    else {
        $varDdosProtectionResourceId = $parParameters.parDdosProtectionResourceId.value
        $parLogAnalyticsWorkspaceId = $parParameters.parLogAnalyticsWorkspaceId.value
        $varAutomationAccountName = $parParameters.parAutomationAccountName.value
        $varPrivateDnsResourceGroupId = $parParameters.parPrivateDnsResourceGroupId.value
    }

    # Get the old policy assignments
    $varListOfUpdatedPolicySetDefinitionIds = Get-PolicyAssignmentsandExemptions $parParameters

    # Generate Default and custom policy sets
    Invoke-PolicyGeneration
    #Install default and custom policy sets
    New-InstallPolicySets
    # Assign default policy sets
    $modDeployDefaultCompliance = New-DefaultCompliance $varDdosProtectionResourceId $parLogAnalyticsWorkspaceId $varAutomationAccountName $varPrivateDnsResourceGroupId
    if (!$modDeployDefaultCompliance) {
        Write-Error "Default compliance deployment script failed." -ErrorAction Stop
    }
    # Assign custom policy sets
    $modDeployCustomCompliance = New-CustomCompliance
    if (!$modDeployCustomCompliance) {
        Write-Error "Custom compliance deployment script failed." -ErrorAction Stop
    }

    #Run policy exemption
    Invoke-PolicyExemption $null $parParameters
    #Run policy evaluation to update policy compliance state
    Invoke-PolicyEvaluation
    $parInvokePolicyScanSync = $parParameters.parInvokePolicyScanSync.value
    if (!$parInvokePolicyScanSync) {
        Write-Information ">>> Currently it is not possible to track progress of policy scan when executed asynchronously. Please execute the policy remediation after 24 hours by selecting the 'policyremediation' deployment option." -InformationAction Continue
    }
    else {
        #Run policy remediation to reflect policy compliance state
        Invoke-PolicyRemediation $null $parParameters
    }

    #Removes the old policy assignments
    Remove-PolicyAssignmentsandExemptions $varListOfUpdatedPolicySetDefinitionIds
}
