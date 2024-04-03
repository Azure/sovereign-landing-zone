# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
SUMMARY: This PowerShell script executes the below list of prerequisite checks to confirm before execution of the New-SovereignLandingZone.ps1

- Verify PowerShell Verion
- Verify Azure PowerShell version
- Verify Azure CLI version
- Update Bicep version
- Check the user executing has the owner permission on the root ("/") scope of the tenant and assign root ("/") permission if the user is missing the same

AUTHOR/S: Cloud for Sovereignty
#>

param (
    $parIsSLZDeployedAtTenantRoot = $true
)

$varSignedInUser = $null;

function Confirm-PowerShellVersion {
    <#

    .SYNOPSIS
    This function checks the current version of PowerShell and prompts the user to install the latest version if the current version is not compatible with the script.
    .EXAMPLE
    Confirm-PowerShellVersion
    .EXAMPLE
    Confirm-PowerShellVersion -varMajorVersion 7 -varMinorVersion 1
    .PARAMETER varMajorVersion
    The major version of PowerShell to check for
    .PARAMETER varMinorVersion
    The minor version of PowerShell to check for

    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$parMajorVersion = 7,

        [Parameter(Mandatory = $false)]
        [int]$parMinorVersion = 0
    )
    $varVersion = $PSVersionTable.PSVersion
    Write-Information "`n>>> Checking if the current version of PowerShell $varVersion is compatible with the script- " -InformationAction Continue

    if ($varVersion.Major -eq $parMajorVersion -and $varVersion.Minor -ge $parMinorVersion) {
        Write-Information "The installed version of PowerShell is compatible with the script." -InformationAction Continue
        return $true
    }
    else {
        Write-Error "The installed version of PowerShell $varVersion is not compatible with the script. Please upgrade to the latest version ($parMajorVersion.$parMinorVersion or above) by using the command 'winget install --id Microsoft.Powershell --source winget' or follow this documentation : https://aka.ms/install-powershell." -ErrorAction Continue
        return $false
    }
}

#reference to individual scripts
. ".\Invoke-Helper.ps1"

function Confirm-AZPSVersion {
    <#

    .SYNOPSIS
    This function checks the current version of Azure PowerShell module and prompts the user to install the latest version if the current version is not compatible with the script.
    .EXAMPLE
    Confirm-AZPSVersion
    .EXAMPLE
    Confirm-AZPSVersion -varMajorVersion 10
    .PARAMETER varMajorVersion
    The major version of Azure PowerShell module to check for

    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$parMajorVersion = 10
    )
    Write-Information "`n>>> Checking the current verison of azure powershell installed..." -InformationAction Continue
    try {
        $varAzpsVersion = (Get-InstalledModule -Name Az).Version
    }
    catch {
        Write-Error "Install the latest version of Azure AZ PowerShell ($parMajorVersion.0 or above) by running this command 'Install-Module -Name Az -AllowClobber -Force'" -ErrorAction Continue
        return $false
    }
    $varCompatibleVersionInstalled = [Version]$varAzpsVersion -ge [Version]"$parMajorVersion.0.0"
    if ($varCompatibleVersionInstalled) {
        Write-Information "The installed version of Azure AZ PowerShell module is compatible with the script." -InformationAction Continue
        return $true
    }
    else {
        Write-Error "The installed version of Azure AZ PowerShell module ($varAzpsVersion) is not compatible with the script. Please upgrade to the latest version ($parMajorVersion.0 or above) by running this command 'Install-Module -Name Az -AllowClobber -Force'" -ErrorAction Continue
        return $false
    }
}

function Confirm-AZCLIVersion {
    <#
        .SYNOPSIS
        This function checks the current version of Azure CLI and prompts the user to install the latest version if the current version is not compatible with the script.
        .EXAMPLE
        Confirm-AZCLIVersion
        .EXAMPLE
        Confirm-AZCLIVersion -varMajorVersion 2 -varMinorVersion 40
        .PARAMETER varMajorVersion
        The major version of Azure CLI to check for
        .PARAMETER varMinorVersion
        The minor version of Azure CLI to check for
    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$parMajorVersion = 2,

        [Parameter(Mandatory = $false)]
        [int]$parMinorVersion = 51
    )
    Write-Information "`n>>> Checking the current verison of azure cli installed - " -InformationAction Continue
    if (Get-Command "az" -errorAction SilentlyContinue) {
        $varAzVersion = ((az version -o tsv) -split "\t")[0] -split "\."
        $varCompatibleVersionInstalled = $varAzVersion[0] -eq $parMajorVersion -and $varAzVersion[1] -ge $parMinorVersion
        if ($varCompatibleVersionInstalled) {
            Write-Information "The installed version of Azure CLI is compatible with the script." -InformationAction Continue
            return $true
        }
    }
    Write-Error "The installed version of Azure CLI $varAzVersion is not compatible with the script. Please upgrade to the latest version of Azure CLI ($parMajorVersion.$parMinorVersion or above) by following the steps in the link - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest." -ErrorAction Continue
    return $false
}

function Confirm-BicepVersion {
    <#
        .SYNOPSIS
        This function checks the current version of Bicep and prompts the user to install the latest version
        .EXAMPLE
        Confirm-BicepVersion
    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$parMajorVersion = 0,

        [Parameter(Mandatory = $false)]
        [int]$parMinorVersion = 20
    )
    Write-Information "`n>>> Checking the current verison of Bicep installed - " -InformationAction Continue
    $varCurrentBicepVersion = $null
    try {
        $varCurrentBicepVersion = ((bicep --version) -split " ")[3]
    }
    catch {
        $varCurrentBicepVersion = $null
    }

    if (($varCurrentBicepVersion -ne "") -and ($null -ne $varCurrentBicepVersion)) {
        ##when bicep version command is run, platform already prints the latest version of the Bicep, so no need to print it again
        $varCompatibleVersionInstalled = [Version]$varCurrentBicepVersion -ge [Version]"$parMajorVersion.$parMinorVersion.0"
        if ($varCompatibleVersionInstalled) {
            Write-Information "The installed version of Bicep is latest." -InformationAction Continue
            return $true
        }
        else {
            Write-Error "Current version of Bicep $varCurrentBicepVersion is not compatible with script. To upgrade to the latest version ($parMajorVersion.$parMinorVersion or above), please use this command 'winget install -e --id Microsoft.Bicep --source winget' " -ErrorAction Continue
            return $false
        }
    }
    else {
        Write-Error "Bicep is not installed. To install to the latest version $varLatestAvailableBicepVersion please use this command 'winget install -e --id Microsoft.Bicep --source winget'. Note: If unable to update the bicep, uninstall the current version and retry installation command" -ErrorAction Continue
        return $false
    }
}

<#
    .SYNOPSIS
    This function Confirm the pre-requisites for the SLZ to be executed
    .EXAMPLE
    Confirm-SLZ-PreRequisites
#>
function Confirm-SLZ-PreRequisites {
    $varPsVersionCompatible = Confirm-PowerShellVersion
    $varAzPsVersionCompatible = Confirm-AZPSVersion
    $varAzCliVersionCompatible = Confirm-AZCLIVersion
    $varBicepVersionCompatible = Confirm-BicepVersion

    if ($varPsVersionCompatible -eq $false -or $varAzPsVersionCompatible -eq $false -or $varAzCliVersionCompatible -eq $false -or $varBicepVersionCompatible -eq $false) {
        Write-Error "After installing missing dependencies, please restart PowerShell and try again" -ErrorAction Stop
    }

    $varSignedInUser = Get-SignedInUser

    # if user is not signed in trigger login
    if ($null -eq $varSignedInUser) {
        Enter-Login
        $varSignedInUser = Get-SignedInUser
    }
    if ($parIsSLZDeployedAtTenantRoot) {
        # check user elevated at root scope
        $varUserElevated = Confirm-UserElevated

        # if user is not elevated at root scope.
        if ($varUserElevated -ne $true) {
            Set-UserElevatePermissions
            Invoke-UserPermissionsConfirmation "Elevate"
        }

        # check owner permissions of the user
        $varUserhasOwnerPermissions = Confirm-UserOwnerPermission

        # if user does not have owner permissions.
        if ($varUserhasOwnerPermissions -ne $true) {
            Set-UserOwnerPermission
            Invoke-UserPermissionsConfirmation "Owner"
        }

        Write-Information "`n>>> Signed in user: $varSignedInUser has the necessary permissions." -InformationAction Continue
    }
}

try {
    Confirm-SLZ-PreRequisites
}
catch {
    Write-Error $_  -ErrorAction Stop
}
