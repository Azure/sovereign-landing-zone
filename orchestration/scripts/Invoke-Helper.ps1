# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
    The powershell script contains definitions of helper functions to be used across all the deployment scripts.
#>

#variables
$varMoveSubscriptionBicepFilePath = '..\moveSubscription\moveSubscription.bicep'
$varAzPortalLink = 'https://portal.azure.com'
$varDonotRetryErrorCodes = New-Object Collections.Generic.List[String]
$vartimeStamp = Get-Date -Format "yyyyMMddTHHmmssffff"
$varTenantDeployment = 'tenant'
$varManagementGroupDeployment = 'managementGroup'
$varParameters = @{}

#variables to support incremental delay for azure resource validation checks (All time in seconds)
$varMaxWaitTimeResourceExistsCheck = 1800
$varStartIntervalResourceExistsCheck = 5
$varMaxIntervalResourceExistsCheck = 60
$varIntervalMultiplierResourceExistsCheck = 5
#variables to support retry for known transient errors
$varMaxRetryAttemptTransientErrorRetry = 6
$varRetryWaitTimeTransientErrorRetry = 60
$varReservedIpAddressRange = @(
    "224.0.0.0/4",
    "255.255.255.255/32",
    "127.0.0.0/8",
    "169.254.0.0/16",
    "168.63.129.16/32",
    "192.168.1.0",
    "192.168.1.1",
    "192.168.1.2",
    "192.168.1.3",
    "192.168.1.255"
)


<#
.Description
    Login to Azure portal
#>
function Enter-Login {
    Write-Information ">>> Initiating a login" -InformationAction Continue
    Connect-AzAccount
}

<#
.Description
    Get details of user
#>
function Get-SignedInUser {

    $varSignedInUserDetails = Get-AzADUser -SignedIn
    if (!$varSignedInUserDetails) {
        Write-Information ">>> No logged in user found." -InformationAction Continue
    }
    else {
        return $varSignedInUserDetails.UserPrincipalName
    }

    return $null
}

<#
.Description
   Confirm the user is owner at the root scope
#>
function Confirm-UserOwnerPermission {
    if ($null -ne $varSignedInUser) {

        Write-Information "`n>>> Checking the owner permissions for user: $varSignedInUser at '/' scope"  -InformationAction Continue
        $varRetrieveOwnerPermissions = Get-AzRoleAssignment `
            -SignInName $varSignedInUser `
            -Scope "/" `
            -RoleDefinitionName "Owner"

        if ($varRetrieveOwnerPermissions.RoleDefinitionName -ne "Owner") {
            Write-Information "Signed in user: $varSignedInUser does not have owner permission to the root '/' scope."  -InformationAction Continue
            return $false
        }
        else {
            Write-Information "Signed in user: $varSignedInUser has owner permissions at the root '/' scope."  -InformationAction Continue
        }
        return $true
    }
    else {
        Write-Error "Logged in user details are empty." -ErrorAction Stop
    }
}

<#
.Description
    Assigns the user with Owner permissions at the root scope
#>
function Set-UserOwnerPermission {
    Write-Information ">>> Assigning user with Owner permissions." -InformationAction Continue

    # Assign "Owner" role to the signed-in user at the root scope "/"
    New-AzRoleAssignment `
        -SignInName $varSignedInUser `
        -Scope "/" `
        -RoleDefinitionName "Owner"
}

<#
.Description
   Confirm the user is elevated at the root scope.
#>
function Confirm-UserElevated {
    if ($null -ne $varSignedInUser) {

        Write-Information "`n>>> Checking user $varSignedInUser is elevated at '/' scope"  -InformationAction Continue
        $varRetrieveUAAPermissions = Get-AzRoleAssignment `
            -SignInName $varSignedInUser `
            -Scope "/" `
            -RoleDefinitionName "User Access Administrator"

        if ($varRetrieveUAAPermissions.RoleDefinitionName -ne "User Access Administrator") {
            Write-Information "Signed in user: $varSignedInUser is not elevated at '/' scope"  -InformationAction Continue
            return $false
        }

        Write-Information "Signed in user: $varSignedInUser is elevated at '/' scope"  -InformationAction Continue
        return $true
    }
    else {
        Write-Error "Logged in user details are empty." -ErrorAction Stop
    }
}
<#
.Description
    Assigns the user with User Access Administrator permissions at the root scope
#>
function Set-UserElevatePermissions {
    Write-Information ">>> Elevating user at root scope." -InformationAction Continue

    # Elevate access to all Azure Resources for a Global Administrator
    Invoke-AzRestMethod -Method Post -Uri "https://management.azure.com/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"
}

<#
.Description
    Confirm the user is elevated at the root scope.
#>
function Invoke-UserPermissionsConfirmation {
    param($parPermissionType)
    Write-Information "`n>>> Confirming user's permissions. This might trigger an auto log out and require the user to login back in a few times" -InformationAction Continue

    $varUserPermissionsElevated = $false
    $varWaitTime = 10
    $varLoopCounter = 0

    while ($varTotalWaitTime -lt $varMaxWaitTimeResourceExistsCheck -and $varUserPermissionsElevated -eq $false) {
        try {
            # Log out to refresh the session
            Get-AzContext | Remove-AzContext -Confirm:$false
            Connect-AzAccount

            if ($parPermissionType -eq "Owner") {
                # check owner permissions of the user
                $varUserPermissionsElevated = Confirm-UserOwnerPermission
            }
            elseif ($parPermissionType -eq "Elevate") {
                # check user elevated at root scope
                $varUserPermissionsElevated = Confirm-UserElevated
            }

            if ($varUserPermissionsElevated -ne $true) {
                Write-Information ">>> Checking the permissions after waiting for $varWaitTime secs. Please ensure that you are logged into the appropriate tenant and did not log in to a different tenant during the script execution." -InformationAction Continue
                $varLoopCounter++
                $varWaitTime = New-IncrementalDelay $varWaitTime $varLoopCounter
                $varTotalWaitTime += $varWaitTime
                Start-Sleep -Seconds $varWaitTime
            }
        }
        catch {
            $_.Exception
            Write-Information ">>> Retrying after waiting for $varWaitTime secs. To stop the retry press Ctrl+C." -InformationAction Continue
            $varLoopCounter++
            $varWaitTime = New-IncrementalDelay $varWaitTime $varLoopCounter
            $varTotalWaitTime += $varWaitTime
            Start-Sleep -Seconds $varWaitTime
        }
    }
}

<#
.Description
   Retrieves the error details on failure of deployment from azure
#>
function Get-FailedDeploymentErrorCodes {
    param($parManagementGroupId, $parDeploymentName, $parDeploymentScope)

    $varErrorCodeList = New-Object Collections.Generic.List[String]
    if ($parDeploymentScope -eq $varTenantDeployment) {
        $varDeploymentError = Get-AzTenantDeploymentOperation `
            -DeploymentName  $parDeploymentName | Where-Object { $_.ProvisioningState -eq "Failed" }
    }
    else {
        $varDeploymentError = Get-AzManagementGroupDeploymentOperation `
            -ManagementGroupId $parManagementGroupId `
            -DeploymentName $parDeploymentName | Where-Object { $_.ProvisioningState -eq "Failed" }
    }

    if ($null -ne $varDeploymentError) {
        if ($varDeploymentError.GetType().IsArray -and $varDeploymentError.count -gt 0) {
            foreach ($error in $varDeploymentError) {
                $varErrorDetails = $error.StatusMessage
                if ($varErrorDetails) {
                    $varErrorCode = Get-ErrorCode $varErrorDetails
                    # add to the list if the error code is not null and does not exists already
                    if ($null -ne $varErrorCode -and !($varErrorCodeList -Contains $varErrorCode)) {
                        $varErrorCodeList.Add($varErrorCode)
                    }
                }
            }
        }
        else {
            $varErrorDetails = $varDeploymentError.StatusMessage
            if ($varErrorDetails) {
                $varErrorCode = Get-ErrorCode $varErrorDetails
                # add to the list if the error code is not null and does not exists already
                if ($null -ne $varErrorCode -and !($varErrorCodeList -Contains $varErrorCode)) {
                    $varErrorCodeList.Add($varErrorCode)
                }
            }
        }
    }
    else {
        return $null
    }
    return $varErrorCodeList
}

<#
.Description
   Checks whether a transient error or not
#>
function  Confirm-Retry {
    param ($parDeploymentErrorCodes)

    $varRetry = $true

    foreach ($varErrorCode in $parDeploymentErrorCodes) {
        if ($varDonotRetryErrorCodes -contains $varErrorCode) {
            $varRetry = $false
            break
        }
    }
    return $varRetry
}

<#
.Description
    Converts the object to array
#>
function Convert-ToArray {
    param ($parObjectToConvert)
    if ($null -eq $parObjectToConvert -or $parObjectToConvert.Length -eq "0") {
        return @()
    }

    $varObjArray = @()
    foreach ($varObject in $parObjectToConvert) {
        $varMap = @{}
        $varObject.psobject.properties | ForEach-Object { $varMap[$_.Name] = $_.Value }
        $varObjArray += $varMap
    }

    return , $varObjArray
}

<#
.Description
    Converts the object to a hash table
#>
function Convert-ToHashTable {
    param ($parObjectToConvert)
    if ($null -eq $parObjectToConvert) {
        return @{}
    }

    $varHashTable = @{}
    $parObjectToConvert.PSObject.properties | ForEach-Object { $varHashTable[$_.Name] = $_.Value }

    return $varHashTable
}

<#
.Description
    Moves the Subscriptions from root management group to platform
#>
function Move-Subscription {
    param($parParameters, $modDeployBootstrapOutputs)

    if ($modDeployBootstrapOutputs) {
        $varConnectivitySubscriptionId = $modDeployBootstrapOutputs.outputs.outConnectivitySubscriptionId.value
        $varIdentitySubscriptionId = $modDeployBootstrapOutputs.outputs.outIdentitySubscriptionId.value
        $varManagementSubscriptionId = $modDeployBootstrapOutputs.outputs.outManagementSubscriptionId.value
    }
    else {
        $varConnectivitySubscriptionId = $parParameters.parConnectivitySubscriptionId.value
        $varIdentitySubscriptionId = $parParameters.parIdentitySubscriptionId.value
        $varManagementSubscriptionId = $parParameters.parManagementSubscriptionId.value
    }

    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $parameters = @{
        parDeploymentPrefix           = $parDeploymentPrefix
        parDeploymentSuffix           = $parDeploymentSuffix
        parConnectivitySubscriptionId = $varConnectivitySubscriptionId
        parIdentitySubscriptionId     = $varIdentitySubscriptionId
        parManagementSubscriptionId   = $varManagementSubscriptionId
    }
    $varDeploymentName = "deploy-move-$vartimeStamp"
    $varLoopCounter = 0
    $varRetry = $true

    while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        try {
            Write-Information ">>> Move subscription started" -InformationAction Continue

            $modMoveSubscription = New-AzManagementGroupDeployment `
                -Name $varDeploymentName `
                -ManagementGroupId $varManagementGroupId `
                -Location $parDeploymentLocation `
                -TemplateFile $varMoveSubscriptionBicepFilePath `
                -TemplateParameterObject $parameters `
                -WarningAction Ignore

            if (!$modMoveSubscription) {
                $varRetry = $false
                Write-Error "Error while executing move subscription" -ErrorAction Stop
            }

            Write-Information ">>> Move subscription completed`n" -InformationAction Continue
            return;
        }
        catch {
            if (!$varRetry) {
                Write-Error ">>> Error occurred during execution. Please try after addressing the above error." -ErrorAction Stop
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
                        Write-Error ">>> Error occurred in move subscription deployment. Please try after addressing the above error." -ErrorAction Stop
                    }
                }
            }
        }
    }
}

<#
.Description
   Caclulates and returns the number of seconds to wait
#>
function New-IncrementalDelay {
    param($parDelay, $parDelayIterator)
    $parDelay = $parDelay + ($parDelayIterator * $varIntervalMultiplierResourceExistsCheck)
    if ($parDelay -ge $varMaxIntervalResourceExistsCheck) {
        $parDelay = $varMaxIntervalResourceExistsCheck
    }
    return $parDelay
}

<#
.Description
   Load all the errors from the json file in a hashtable
#>
function Get-DonotRetryErrorCodes {
    param ()
    $varErrorFile = Get-Content -Path '../const/doNotRetryErrorCodes.json' | ConvertFrom-Json
    $varErrorFile.errorCodes | ForEach-Object {
        $varDonotRetryErrorCodes.add($_.code)
    }
}
<#
.Description
   Retrieves the error code on failure of deployment from json object
#>
function Get-ErrorCode {
    param ($parErrorString)

    $varLastIndexOfCode = $parErrorString.LastIndexOf("(Code:")

    # Find the position of the closing parenthesis after "Code:"
    $varClosingParenthesisIndex = $parErrorString.IndexOf(")", $varLastIndexOfCode)

    # Extract the value of 'Code'
    $varErrorCode = $parErrorString.Substring($varLastIndexOfCode + 6, $varClosingParenthesisIndex - $varLastIndexOfCode - 6).Trim()

    return $varErrorCode
}

<#
.Description
    Checks the required parameters are passed based on the deployment
#>
function Confirm-Parameters($parParameters) {
    $varMissingParameters = New-Object Collections.Generic.List[String]
    $varArrayParameters = @("parAllowedLocations", "parAllowedLocationsForConfidentialComputing", "parPolicyDefinitionReferenceIds")
    Foreach ($varParameter in $parParameters) {
        if ($varParameter -in $varArrayParameters -and $varParameters.$varParameter.value.count -eq 0) {
            if (!$parAttendedLogin) {
                $varMissingParameters.add($varParameter)
            }
            else {
                [string[]] $varArray = @()
                $varArray = Read-Host "Please enter the list of $varParameter with a comma between each"
                if ($varArray[0] -eq "") {
                    Write-Error "$varParameter value not found" -ErrorAction Stop
                }
                $varParameters.$varParameter.value = $varArray.Split(',')
            }
        }
        elseif (($null -eq $varParameters.$varParameter.value) -or [string]::IsNullOrEmpty($varParameters.$varParameter.value.ToString()) -or ($varParameters.$varParameter.value -eq "{}")) {
            $varParameters.$varParameter.value = $null
            if (!$parAttendedLogin) {
                $varMissingParameters.add($varParameter)
            }
            else {
                $varParameters.$varParameter.value = $(Read-Host -prompt "Please provide the value for $varParameter")
                if ($varParameters.$varParameter.value -eq "") {
                    Write-Error "$varParameter value not found" -ErrorAction Stop
                }
            }
        }
        elseif ($varParameters.$varParameter.value.count -gt 1) {
            $varValue = $varParameters.$varParameter.value
            if ($varValue -is [array]) {
                foreach ($val in $varValue) {
                    $result = Confirm-ObjectType($val)
                    if ($result -eq $false) {
                        $varMissingParameters.add($varParameter)
                    }
                }
            }
            elseif ($varValue -is [object]) {
                $result = Confirm-ObjectType($varValue)
                if ($result -eq $false) {
                    $varMissingParameters.add($varParameter)
                }
            }
            elseif (($null -eq $varValue) -or [string]::IsNullOrEmpty($varValue) -or ($varValue -eq "{}")) {
                $varParameters.$varParameter.value = $null
                return $false
            }
        }
    }
    if ($varMissingParameters.count -gt 0) {
        Write-Error "Following parameters are missing : $varMissingParameters" -ErrorAction Stop
    }

    # Check Gateway subnet is in the reserved Ip address list.
    $varGatewaySubnet = $parParameters.parGatewaySubnet.value
    $varIsGatewayReservedIpAddress = Confirm-IPAddressIsReserved($varGatewaySubnet)
    if (($null -ne $varGatewaySubnet) -and ($true -eq $varIsGatewayReservedIpAddress)) {
        Show-IpAddressError("The Gatewary Subnet Ip", $varGatewaySubnet)
    }

    # Check Azure Firewall Subnet is in the reserved Ip address list.
    $varAzureFirewallSubnet = $parParameters.parAzureFirewallSubnet.value
    $varIsFirewallReservedIpAddress = Confirm-IPAddressIsReserved($varAzureFirewallSubnet)
    if (($null -ne $varAzureFirewallSubnet) -and ($true -eq $varIsFirewallReservedIpAddress)) {
        Show-IpAddressError("The Azure Firewall Subnet Ip", $varAzureFirewallSubnet)
    }

     # Check parCustomerPolicySets.
     Confirm-CustomerPolicySets($varParameters.parCustomerPolicySets.value)
}

<#
.Description
    Show Ip Address error which is in reserved Ip Address range list.
#>
function Show-IpAddressError($parMessage, $parIp) {
    Write-Information "$parMessage $parIp is in the reserved IP address list:" -InformationAction Continue
    foreach ($varIp in $varReservedIpAddressRange) {
        Write-Information $varIp -InformationAction Continue
    }

    Write-Error "Please do not use reserved IP addresses. Update parameters and try again." -ErrorAction Stop
}

<#
.Description
    Checks/confirms whether the value of Ip Address range is in reserved Ip Address range list.
#>
function Confirm-IPAddressIsReserved($parIp) {
    if ($null -eq $parIp) {
        return $false
    }

    Foreach ($varReservedIpAddress in $varReservedIpAddressRange) {
        try {
            # Parse the IP address and subnet
            $varReservedIp = [IPAddress]::Parse($varReservedIpAddress.Split("/")[0])
            $varReservedIpRange = $varReservedIpAddress.Split("/")[1]
            $varIp = [IPAddress]::Parse($parIp.Split("/")[0])
            $varIpRange = $parIp.Split("/")[1]

            # Check if the IP address falls within the reserved IP address
            $varIsReservedIp = (($varReservedIp.Address -eq $varIp.Address) -and ($varReservedIpRange -eq $varIpRange))

            if ($varIsReservedIp) {
                return $true
            }
        }
        catch {
            Write-Error $_ -ErrorAction Stop
        }
    }

    return $false
}

<#
.Description
    Checks the required Object type parameters are passed based on the deployment.
#>
function Confirm-ObjectType($parParameter) {
    if (($null -eq $parParameter)) {
        return $false
    }

    $varMembers = $parParameter.PSObject.Properties | Select-Object Name, Value
    foreach ($varMember in $varMembers) {
        if (($null -eq $varMember.value) -or [string]::IsNullOrEmpty($varMember.value) -or ($varMember.value -eq "")) {
            return $false
        }
    }

    return $true
}

<#
.Description
    Checks that the policy sets are available before assigning
#>
function Confirm-PolicySetExists {
    param ($parManagementGroupId, $parPolicySetType)

    if ($parPolicySetType -eq 'custom') {
        $varPolicySetsPath = "../../custom/policies/definitions"
    }
    else {
        $varPolicySetsPath = "../../modules/compliance/policySetDefinitions"
    }

    $varLoopCounter = 0
    $varWaitTime = $varStartIntervalResourceExistsCheck
    $varTotalWaitTime = 0

    while ($varTotalWaitTime -lt $varMaxWaitTimeResourceExistsCheck) {
        try {
            Get-ChildItem -Recurse -Path "$varPolicySetsPath" -Filter "*.json" | ForEach-Object {

                $varPolicyDef = Get-Content $_.PSPath | ConvertFrom-Json -Depth 100

                if (($varPolicyDef.properties.policyDefinitions).Count -ne 0) {
                    $parPolicyName = $varPolicyDef.name + ".v" + $varPolicyDef.properties.metadata.version

                    $varPolicySet = Get-AzPolicySetDefinition -Name $parPolicyName -ManagementGroupName $parManagementGroupId
                    if (!$varPolicySet) {
                        Write-Error "$parPolicyName policy set not found." -ErrorAction stop
                    }
                }
            }

            Write-Information ">>> All required policy sets were found."  -InformationAction Continue
            return $true
        }
        catch {
            $varLoopCounter++
            $varWaitTime = New-IncrementalDelay $varWaitTime $varLoopCounter
            Write-Information ">>> Searching for the required policy sets after waiting for $varWaitTime seconds." -InformationAction Continue
            $varTotalWaitTime += $varWaitTime
            Start-Sleep -Seconds $varWaitTime
        }
    }

    return $false
}

<#
.Description
    Checks whether subscriptions are created or not.
#>
function Confirm-SubscriptionsExists() {
    param($parConnectivitySubscriptionId, $parIdentitySubscriptionId, $parManagementSubscriptionId)
    $varLoopCounter = 0
    $varWaitTime = $varStartIntervalResourceExistsCheck
    $varTotalWaitTime = 0
    $varSubscriptionExists = $false
    while ($varTotalWaitTime -lt $varMaxWaitTimeResourceExistsCheck -and $varSubscriptionExists -eq $false) {
        try {
            $varConnectivityID = Get-AzSubscription -SubscriptionId $parConnectivitySubscriptionId -WarningAction Ignore
            $varManagementID = Get-AzSubscription -SubscriptionId $parManagementSubscriptionId -WarningAction Ignore
            $varIdentityID = Get-AzSubscription -SubscriptionId $parIdentitySubscriptionId -WarningAction Ignore
            if ((!$varConnectivityID) -or (!$varManagementID) -or (!$varIdentityID)) {
                Write-Error "Subscription Not Found" -ErrorAction stop
            }
            $varSubscriptionExists = $true
        }
        catch {
            $varLoopCounter++
            $varWaitTime = New-IncrementalDelay $varWaitTime $varLoopCounter
            Write-Information ">>>One or more subscription not found. Retrying after $varWaitTime seconds" -InformationAction Continue
            $varTotalWaitTime += $varWaitTime
            Start-Sleep -Seconds $varWaitTime
        }
    }

    return $varSubscriptionExists
}

<#
.Description
   Processing parameters from JSON and creating a hash table
#>
function Read-ParametersValue($parJsonParamFilePath) {
    $varSlzParameters = Get-Content -Path $parJsonParamFilePath | ConvertFrom-Json
    $varAllowEmptyParameters = @("parExpressRouteGatewayConfig", "parVpnGatewayConfig", "parCustomerPolicies")
    $varSlzParameters.parameters.psobject.properties | ForEach-Object {
        if (($null -eq $_.value.Value -or $_.value.Value.count -eq 0) -and ($varAllowEmptyParameters -NotContains $_.Name)) {
            $varParameters.add($_.Name, (new-Object PsObject -property @{value = $_.value.defaultValue; defaultValue = $_.value.defaultValue }))
        }
        else {
            $varParameters.add($_.Name, (new-Object PsObject -property @{value = $_.value.Value; defaultValue = $_.value.defaultValue }))
        }
    }
    return $varParameters
}

<#
.Description
    Checks Sovereign Landing Zone Prerequisites for the deployment.
#>
function Confirm-Prerequisites {
    param($parIsSLZDeployedAtTenantRoot)
    Write-Information ">>> Checking Sovereign Landing Zone Prerequisites for the deployment" -InformationAction Continue
    $varConfirmPrerequisites = '.\Confirm-SovereignLandingZonePrerequisites.ps1'
    & $varConfirmPrerequisites -parAttendedLogin $parAttendedLogin -parIsSLZDeployedAtTenantRoot $parIsSLZDeployedAtTenantRoot -ErrorAction Stop
    Write-Information ">>> Checking Sovereign Landing Zone Prerequisites is complete." -InformationAction Continue
    return
}

<#
.Description
    Show management group information with a link to management group's azure portal
#>
function Show-ManagementGroupInfo {
    param($parParameters)

    if (!$parAttendedLogin) {
        return
    }

    $parDeploymentPrefix = [System.Uri]::EscapeDataString($parParameters.parDeploymentPrefix.value)
    $parTopLevelManagementGroupName = [System.Uri]::EscapeDataString($parParameters.parTopLevelManagementGroupName.value)
    $parDeploymentSuffix = [System.Uri]::EscapeDataString($parParameters.parDeploymentSuffix.value)
    $varTenantId = (Get-AzContext).Tenant.Id
    $varManagementGroupLink = "$varAzPortalLink/#view/Microsoft_Azure_ManagementGroups/ManagmentGroupDrilldownMenuBlade/~/overview/tenantId/$varTenantId"
    $varManagementGroupLink = "$varManagementGroupLink/mgId/$parDeploymentPrefix$parDeploymentSuffix/mgDisplayName/$parTopLevelManagementGroupName/mgCanAddOrMoveSubscription~/true/mgParentAccessLevel/Owner/defaultMenuItemId/overview/drillDownMode~/true"
    $varManagementGroupInfo = "If you want to learn more about your management group, please click following link.`n`n"
    $varManagementGroupInfo = "$varManagementGroupInfo$varManagementGroupLink`n`n"

    Write-Information  ">>> $varManagementGroupInfo" -InformationAction Continue
}

<#
.Description
    Show dashboard information with a link to portal dashboard.
#>
function Show-DashboardInfo {
    param($parParameters, $modDeployBootstrapOutputs)

    if ($modDeployBootstrapOutputs) {
        $varManagementSubscriptionId = $modDeployBootstrapOutputs.outputs.outManagementSubscriptionId.value
    }
    else {
        $varManagementSubscriptionId = $parParameters.parManagementSubscriptionId.value
    }

    if (!$parAttendedLogin) {
        return
    }

    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varSignedInUser = Get-SignedInUser
    $varResourceGroupName = "$parDeploymentPrefix-rg-dashboards-$parDeploymentLocation$parDeploymentSuffix"
    $varDashboardName = "$parDeploymentPrefix-Sovereign-Landing-Zone-Dashboard-$parDeploymentLocation$parDeploymentSuffix"
    $varUserDomain = $varSignedInUser.Substring($varSignedInUser.IndexOf("@"))
    $varDashboardLink = "$varAzPortalLink/#$varUserDomain/dashboard/arm/subscriptions/$varManagementSubscriptionId"
    $varDashboardLink = "$varDashboardLink/resourceGroups/$varResourceGroupName/providers/Microsoft.Portal/dashboards/$varDashboardName"
    $varDashboardInfo = "Now your compliance dashboard is ready for you to get insights. If you want to learn more, please click following link.`n`n$varDashboardLink`n`n"

    Write-Information  ">>> $varDashboardInfo" -InformationAction Continue
}

<#
.Description
    Register resource provider.
#>
function Register-ResourceProvider {
    param($parProviderNamespace)

    $varResourceProvider = $null
    $varLoopCounter = 0

    Register-AzResourceProvider -ProviderNamespace $parProviderNamespace
    $varResourceProvider = Get-AzResourceProvider -ProviderNamespace $parProviderNamespace
    while ($null -eq $varResourceProvider -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        Start-Sleep -Seconds $varRetryWaitTimeTransientErrorRetry
        $varResourceProvider = Get-AzResourceProvider -ProviderNamespace $parProviderNamespace
        $varLoopCounter++
    }
}

<#
.Description
    Check the bastion subnet value is provided if the deploy bastion is true.
#>
function Confirm-BastionRequiredValue {
    param ($parDeployBastion, $parSubnets)

    if ($parDeployBastion) {
        $varAzureBastionSubnet = ($parSubnets | Where-Object { $_.name -eq 'AzureBastionSubnet' }).ipAddressRange
        if ([string]::IsNullOrEmpty($varAzureBastionSubnet)) {
            Write-Error ">>> Missing parameter value for Azure Bastion subnet IP address range. Please try after addressing the above error." -ErrorAction Stop
        }
    }
}
<#
.Description
Get Private DNS Resource Group Id from the Private DNS Zones output
#>
function Get-PrivateDnsResourceGroupId {
    param ($parPrivateDnsZones, $parParameters)
    $varPrivateDnsResourceGroupId = ""
    $varDNSZonesResourceId = $parPrivateDnsZones.Count -gt 0 ? ($parPrivateDnsZones[0].id).ToString() : ""
    if (-not [string]::IsNullOrEmpty($varDNSZonesResourceId)) {
        $parDeploymentLocation = $parParameters.parDeploymentLocation.value
        $varPattern = "(.*)(?<=$([regex]::escape($parDeploymentLocation)))"
        $varRegExResult = $varDNSZonesResourceId | Select-String -Pattern $varPattern
        $varPrivateDnsResourceGroupId = $varRegExResult.Matches[0].Value
    }
    return  $varPrivateDnsResourceGroupId
}
<#
.Description
Get Resource Name from Resource Id
#>
function Get-ResourceNameFromId {
    param($parResourceId)
    $varResourceName = ""
    if (-not [string]::IsNullOrEmpty($parResourceId)) {
        $parResourceId = $parResourceId -split '/'
        $varResourceName = $parResourceId[$parResourceId.Length - 1]
    }
    return $varResourceName
}
<#
.Description
Get Resource Type from Resource Id
#>
function Get-ResourceTypefromId {
    param($parResourceId)
    $varResourceType = ""
    if (-not [string]::IsNullOrEmpty($parResourceId)) {
        $parResourceId = $parResourceId -split '/'
        $varResourceType = $parResourceId[$parResourceId.Length - 2]
    }
    return $varResourceType
}

<#
.DESCRIPTION
Create a new object with the output data
#>
function New-OutputObject {
    param($parResourceName, $parResourceType, $parResourceId, $parDeploymentName, $parComments)
    $varDeploymentData = [PSCustomObject]@{
        "Resource Name"     = $parResourceName
        "Resource Type"     = $parResourceType
        "Resource Id"       = $parResourceId
        "Deployment Module" = $parDeploymentName
        "Comments"          = $parComments
    }
    return $varDeploymentData
}

<#
.Description
    Update parameter file after deployment
#>
function Out-DeploymentParameters {
    param($parDeploymentName, $modDeploymentOutputs, $parManagementGroupId, $parParameters)
    $varFilename = $parManagementGroupId + "_" + $parParameters.parDeploymentStartTime + ".csv"
    # Set the path of the folder you want to check/create
    $varFolderPath = "outputs"

    # Check if the folder exists
    if (-Not (Test-Path -Path $varFolderPath -PathType Container)) {
        # If the folder does not exist, create it
        New-Item -ItemType Directory -Path $varFolderPath -Force
        Write-Information "Folder created: $varFolderPath" -InformationAction Continue
    }
    $varExistingCsvFilePath = $varFolderPath + "\" + $varFilename

    $varCsvData = @()
    if ($parDeploymentName -eq "bootstrap") {
        $varDeploymentData = New-OutputObject $modDeploymentOutputs.outputs.outManagementSubscriptionName.value "Subscription" $modDeploymentOutputs.outputs.outManagementSubscriptionId.value $parDeploymentName "Used by platform as parManagementSubscriptionId"
        $varCsvData += $varDeploymentData
        $varDeploymentData = New-OutputObject $modDeploymentOutputs.outputs.outIdentitySubscriptionName.value "Subscription" $modDeploymentOutputs.outputs.outIdentitySubscriptionId.value $parDeploymentName "Used by platform as parIdentitySubscriptionId"
        $varCsvData += $varDeploymentData
        $varDeploymentData = New-OutputObject $modDeploymentOutputs.outputs.outConnectivitySubscriptionName.value "Subscription" $modDeploymentOutputs.outputs.outConnectivitySubscriptionId.value $parDeploymentName "Used by platform as parConnectivitySubscriptionId"
        $varCsvData += $varDeploymentData
        $varDeploymentData = New-OutputObject "Billing Scope" "billingScope" $parParameters.parSubscriptionBillingScope.value $parDeploymentName "Can be used for ALZ Vending module as subscriptionBillingScope"
        $varCsvData += $varDeploymentData
        foreach ($child in $modDeploymentOutputs.outputs.outLandingZoneChildrenManagementGroupIds.value) {
            $varResourceName = Get-ResourceNameFromId $child
            $varResourceType = Get-ResourceTypefromId $child
            $varDeploymentData = New-OutputObject $varResourceName $varResourceType $child $parDeploymentName ""
            $varCsvData += $varDeploymentData
        }
        foreach ($child in $modDeploymentOutputs.outputs.outPlatformChildrenManagementGroupIds.value) {
            $varResourceName = Get-ResourceNameFromId $child
            $varResourceType = Get-ResourceTypefromId $child
            $varDeploymentData = New-OutputObject $varResourceName $varResourceType $child $parDeploymentName ""
            $varCsvData += $varDeploymentData
        }
    }
    elseif ($parDeploymentName -eq "platform") {
        $varPrivateDnsResourceGroupId = Get-PrivateDnsResourceGroupId $modDeploymentOutputs.outputs.outPrivateDNSZones.value $parParameters
        $varDdosProtectionResourceId = $modDeploymentOutputs.outputs.outDdosProtectionResourceId.value
        $varLogAnalyticsResourceId = $modDeploymentOutputs.outputs.outLogAnalyticsWorkspaceId.value
        $varAutomationAccountId = $modDeploymentOutputs.outputs.outAutomationAccountName.value
        $varHubNetworkId = $modDeploymentOutputs.outputs.outHubVirtualNetworkId.value
        if (-not [string]::IsNullOrEmpty($varDdosProtectionResourceId)) {
            $varResourceName = Get-ResourceNameFromId $varDdosProtectionResourceId
            $varResourceType = Get-ResourceTypefromId $varDdosProtectionResourceId
            $varDeploymentData = New-OutputObject $varResourceName $varResourceType $varDdosProtectionResourceId $parDeploymentName "Used by platform as parDdosProtectionResourceId"
            $varCsvData += $varDeploymentData
        }
        if (-not [string]::IsNullOrEmpty($varLogAnalyticsResourceId)) {
            $varResourceName = Get-ResourceNameFromId $varLogAnalyticsResourceId
            $varResourceType = Get-ResourceTypefromId $varLogAnalyticsResourceId
            $varDeploymentData = New-OutputObject $varResourceName $varResourceType $varLogAnalyticsResourceId $parDeploymentName "Used by platform as parLogAnalyticsWorkspaceId"
            $varCsvData += $varDeploymentData
        }
        if (-not [string]::IsNullOrEmpty($varPrivateDnsResourceGroupId)) {
            $varResourceName = Get-ResourceNameFromId $varPrivateDnsResourceGroupId
            $varResourceType = Get-ResourceTypefromId $varPrivateDnsResourceGroupId
            $varDeploymentData = New-OutputObject $varResourceName $varResourceType $varPrivateDnsResourceGroupId $parDeploymentName "Used by platform as parPrivateDnsResourceGroupId"
            $varCsvData += $varDeploymentData
        }

        if (-not [string]::isNullOrEmpty($varAutomationAccountId)) {
            $varResourceName = $varAutomationAccountId
            $varResourceType = "AutomationAccount"
            $varDeploymentData = New-OutputObject $varResourceName $varResourceType $varAutomationAccountId $parDeploymentName "Used by platform as parAutomationAccountName"
            $varCsvData += $varDeploymentData
        }
        if (-not [string]::IsNullOrEmpty($varHubNetworkId)) {
            $varResourceName = Get-ResourceNameFromId $varHubNetworkId
            $varResourceType = Get-ResourceTypefromId $varHubNetworkId
            $varDeploymentData = New-OutputObject $varResourceName $varResourceType $varHubNetworkId $parDeploymentName "Used by platform as parHubVirtualNetworkId"
            $varCsvData += $varDeploymentData
        }
        $varDeploymentData = New-OutputObject "DeploymentLocation" "Location" $parParameters.parDeploymentLocation.value $parDeploymentName "Can be used for ALZ Vending module as virtualNetworkLocation"
        $varCsvData += $varDeploymentData
    }
    # If the existing CSV file exists, read its content
    if (Test-Path -Path $varExistingCsvFilePath) {
        $varExistingData = Import-Csv -Path $varExistingCsvFilePath
    }
    else {
        # If the file doesn't exist, create an empty array
        $varExistingData = @()
    }
    # Append the new data to the existing data
    $varUpdatedData = $varExistingData + $varCsvData

    # Save the updated data to the CSV file
    $varUpdatedData | Export-Csv -Path $varExistingCsvFilePath -NoTypeInformation
}

<#
.Description
    Checks whether the Az Resources's version is later than or equal version 7.0.0, which contains breaking changes and could break existing SLZ scripts.
#>
function Confirm-AzResourceVersion {
    $varAzResourcesVersion = (Get-InstalledModule -Name Az.Resources).Version.replace("-preview", "")
    $varVersion = [Version]$varAzResourcesVersion -ge [Version]"7.0.0"
    return $varVersion
}

<#
.Description
    Checks whether the file exists or not.
#>
function Confirm-FileExists {
    param($parFilePath)
    # Check if the file path exists
    if (Test-Path $parFilePath) {
        Write-Host "The file $parFilePath exists."
    } else {
        Write-Error ">>> The file $parFilePath does not exist. Please try again after addressing this error." -ErrorAction Stop
    }
}

<#
.Description
    Checks whether the json file format is valid or not.
#>
function Confirm-JsonFileFormat { 
    param($parFilePath)

    # Try to convert the JSON file to a PowerShell object
    try {
        Get-Content $parFilePath -Raw | ConvertFrom-Json
        Write-Host "The file $parFilePath contains valid JSON format."
    } catch {
        Write-Error ">>> The file $parFilePath contains invalid JSON format. Please try again after addressing this error. Error: $_" -ErrorAction Stop
    }
}

<#
.Description
    Checks whether the json file format is valid or not.
#>
function Confirm-CustomerPolicySets { 
    param($parCustomerPolicySets)

    # Try to convert the JSON file to a PowerShell object
    foreach($varCustomerPolicySet in $parCustomerPolicySets) {    
        if ($null -ne $varCustomerPolicySet.policyParameterFilePath -and $varCustomerPolicySet.policyParameterFilePath -ne "") {
            Confirm-FileExists($varCustomerPolicySet.policyParameterFilePath)
            Confirm-JsonFileFormat($varCustomerPolicySet.policyParameterFilePath)
        }
    }
}