# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
SUMMARY: This PowerShell script leverages ALZ's invoke-PolicyToBicep.ps1 to generate new slz-defaultandCustomPolicyDefinitions.bicep with SLZ defaulat and
custom policies. It mainly performs the following steps:

- copy policy set definitions files that have atleast one policy from current definitions folder to ..\..\dependencies\infra-as-code\bicep\modules\policy\definitions\lib\policy_set_definitions folder

- call ..\..\dependencies\scripts\Invoke-PolicyToBicep.ps1

- merge ..\..\dependencies\infra-as-code\bicep\modules\policy\definitions\lib\policy_definitions\_policyDefinitionsBicepInput.txt
  with ..\..\dependencies\infra-as-code\bicep\modules\policy\definitions\lib\policy_set_definitions\_policySetDefinitionsBicepInput.txt
  into newCustomPolicyDefinitions.bicep

- replace ..\dependencies\infra-as-code\bicep\modules\policy\definitions\slz-defaultandCustomPolicyDefinitions.bicep with updated slz-defaultandCustomPolicyDefinitions.bicep

This design is based on ALZ automation that syncs new policies from enterprise-scale repo
for more details please check this link https://github.com/Azure/ALZ-Bicep/wiki/PolicyDeepDive

AUTHOR/S: Cloud for Sovereignty
VERSION: 1.0.0
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "False Positive")]

[CmdletBinding(SupportsShouldProcess)]
param (
  [Parameter()]
  [string]
  $parDestRootPath = "../../dependencies/infra-as-code/bicep/modules/policy",
  [string]
  $parDefinitionsPath = "definitions/lib/policy_definitions",
  [string]
  $parDefinitionsLongPath = "$parDestRootPath/$parDefinitionsPath",
  [string]
  $parDefinitionsSetPath = "definitions/lib/policy_set_definitions",
  [string]
  $parDefinitionsSetLongPath = "$parDestRootPath/$parDefinitionsSetPath",
  [string]
  $parDefaultPoliciesRootPath = "../../modules/compliance/policySetDefinitions",
  [string]
  $parCustomPoliciesRootPath = "../../custom/policies/definitions",
  [string]
  $parSlzPolicyPattern = "([Cc]onfidential|[Cc]orp|[Gg]lobal|[Oo]nline|[Cc]onnectivity|[Dd]ecommissioned|[Ii]dentity|[Ll]andingzone|[Mm]anagement|[Pp]latform|[Ss]andbox)",
  [string]
  $parSlzCustomPolicyDefinitionSetFilePattern = "slz$parSlzPolicyPattern" + "Custom",
  [string]
  $parSlzPolicySetDefinitonTxtFile = "$parDefinitionsSetLongPath/_slzPolicySetDefinitionsBicepInput.txt",
  [string]
  $parAlzPolicySetDefinitonTxtFile = "$parDefinitionsSetLongPath/_alzPolicySetDefinitionsBicepInput.txt",
  [string]
  $parTempPolicyDefinitionOutput = "tempCustomPolicyDefinitions.bicep",
  [string]
  $parTempSLZPolicySetDefinitionOutput = "slzTempCustomPolicySetDefinitions.bicep",
  [string]
  $parTempALZPolicySetDefinitionOutput = "alzTempPolicySetDefinitions.bicep",
  $parAttendedLogin = $true
)

<#
.Description
Move all SLZ default and custom policy json files to destPath
#>
function Move-PolicySetDefinitions {
  [CmdletBinding(SupportsShouldProcess)]
  param([string] $parRootPath)

  $varPolicySetDefinitionFiles = Get-ChildItem -Path "$parRootPath/*.json"
  foreach ($varFile in $varPolicySetDefinitionFiles) {
    Write-Debug "Processing $varFile.Name"

    $varFilePath = $parRootPath + "/" + $varFile.Name
    $varJsonContent = Get-Content $varFilePath | ConvertFrom-Json

    if ($varJsonContent.properties.policyDefinitions.Length -gt 0) {
      Copy-Item $varFilePath  -Destination "$parDefinitionsSetLongPath"
      Write-Debug ">>> copied $varFilePath to $parDefinitionsSetLongPath"
    }
    else {
      Write-Debug ">>> $varFile.Name not copied to $parDefinitionsSetLongPath"
    }
  }
}

<#
.Description
 Copy files to destination path
#>
function Copy-SlzCustomPolicyDefinitionsBicep {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  $varDestinationFolder = "$parDestRootPath/definitions/"
  Write-Information ">>> Initiating copy of alz-PolicyDefinitions.bicep, slz-CustomPolicySetDefinitions.bicep and alzPolicySetDefinitions.bicep to $varDestinationFolder" -InformationAction Continue
  Copy-Item "../policyInstallation/alz-PolicyDefinitions.txt" -Destination "$varDestinationFolder\alz-PolicyDefinitions.bicep"
  Copy-Item "../policyInstallation/slz-CustomSLZPolicySetDefinitions.txt" -Destination "$varDestinationFolder\slz-CustomPolicySetDefinitions.bicep"
  Copy-Item "../policyInstallation/alz-DefaultPolicySetDefinitions.txt" -Destination "$varDestinationFolder\alzPolicySetDefinitions.bicep"
  Write-Information ">>> copied alz-PolicyDefinitions.bicep, slz-CustomPolicySetDefinitions.bicep and alzPolicySetDefinitions.bicep to $varDestinationFolder" -InformationAction Continue
}

<#
.Description
Remove existing policy set files.
#>
function Remove-ExistingPolicySetFiles {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  <# For slz custom policies #>
  Write-Information ">>> filtering custom policy using $parSlzCustomPolicyDefinitionSetFilePattern" -InformationAction Continue
  Get-ChildItem -Path "$parDefinitionsSetLongPath" -Filter *.json | Where-Object { $_.Name -match $parSlzCustomPolicyDefinitionSetFilePattern } | Remove-Item
  Write-Information ">>> removed $parDefinitionsSetLongPath/slz*Custom*" -InformationAction Continue

}

<#
.Description
Create new policy definition bicep file.
#>
function Invoke-ALZScript {
  # leverage ALZ script to add new policies/policy-sets into its bicep which slz depends on
  Write-Information ">>> call Invoke-PolicyToBicep.ps1 to regenerate .txt reference files" -InformationAction Continue
  & ..\..\dependencies\scripts\Invoke-PolicyToBicep.ps1 -rootPath "$parDestRootPath"
}

<#
.Description
Create new policy definition bicep file.
#>
function New-AlzPolicyDefinitionsBicepFile {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  $varPolicyDefinitionsBicepInput = "$parDefinitionsLongPath/_policyDefinitionsBicepInput.txt"
  $varCustomPolicyDefinitionsBicepFile = "$parDestRootPath/definitions/alz-PolicyDefinitions.bicep"
  $varKeepCopying = $true

  # processing animation for attended run
  if ($parAttendedLogin) {
    $varDelay = 1000
    $varStartLeft = [Console]::CursorLeft
    $varStartTop = [Console]::CursorTop
    $varOriginalColor = [Console]::ForegroundColor
    $varLoadingChars = @('-', '\', '|', '/')
    $varPos = 0
  }

  try {
    Set-Content -Path $parTempPolicyDefinitionOutput -Value "//`r`n// auto-generated-slz-policy-bicep-file by Cloud for Sovereignty team`r`n//"
    Get-Content $varCustomPolicyDefinitionsBicepFile | ForEach-Object {
      if ($_ -match '<!--\s*alzCustomPolicyDefinitionsReplacement([Ss]tart|[Ee]nd)\s*-->') {
        if ($_ -match '.+([Ss]tart)\s*-->') {
          $varKeepCopying = $false

          Add-Content -Path $parTempPolicyDefinitionOutput -Value "// start"
          # copy $varPolicyDefinitionsBicepInput
          Get-Content $varPolicyDefinitionsBicepInput | Add-Content -Path $parTempPolicyDefinitionOutput
          Add-Content -Path $parTempPolicyDefinitionOutput -Value "// end"

          if ($parAttendedLogin) {
            Flush_Output "[*] loading from auto-gen file..." $varDelay $varStartLeft $varStartTop $varOriginalColor
          }
        }
        elseif ($_ -match ".+([Ee]nd)\s*-->") {
          $varKeepCopying = $true
        }
      }
      else {
        # write line to $parTempPolicyDefinitionOutput
        if ($varKeepCopying) {
          Add-Content -Path $parTempPolicyDefinitionOutput -Value $_

          if ($parAttendedLogin) {
            $varPos = $varPos + 1
            $varLoadingCh = $varLoadingChars[$($varPos % $varLoadingChars.Length)]
            Flush_Output "[$varLoadingCh] loading from original file..." 0 $varStartLeft $varStartTop Blue
          }
        }
      }
    } #end of Foreach
    if ($parAttendedLogin) {
      [Console]::ForegroundColor = $varOriginalColor
    }
  }
  catch {
    Write-Error "Error in merging new policy/policy-set: $_.Exception.Message"
  }
  #replace $varCustomPolicyDefinitionsBicepFile with $parTempPolicyDefinitionOutput
  Copy-Item $parTempPolicyDefinitionOutput -Destination $varCustomPolicyDefinitionsBicepFile -force
}
<#
.Description
Create 2 slz policy files one with global policies and other with remainder slz policies from _policySetDefinitionsBicepInput.txt
#>
function New-SLZPolicySetDefinitonsBicepInputFiles {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  $varPolicySetDefTextFile = Get-Content  "$parDefinitionsSetLongPath/_policySetDefinitionsBicepInput.txt"
  #arraylist that will contain each slz policy set json as an array
  $varSlzPolicySetList = New-Object -TypeName 'System.Collections.ArrayList'
  #arraylist that will contain each slz policy set parameters
  $varSlzPolicyParams = New-Object -TypeName 'System.Collections.ArrayList'
  #initializing array to contain slz policy set.
  <# Once a policy set parsing is complete, the array will be appended to 'slzPolicySetList' #>
  [String[]] $varSlzPolicySet = @()

  #arraylist that will contain each alz policy set json as an array
  $varAlzPolicySetList = New-Object -TypeName 'System.Collections.ArrayList'
  #arraylist that will contain each alz policy set parameters
  $varAlzPolicyParams = New-Object -TypeName 'System.Collections.ArrayList'
  #initializing array to contain alz policy set.
  <# Once a policy set parsing is complete, the array will be appended to 'alzPolicySetList' #>
  [String[]] $varAlzPolicySet = @()

  <# declaring patterns #>
  $varNameString = 'name:'
  $varPolicyNamePattern = '(?<=name: )(.*)'
  $varSlzPolicyNamePrefix = 'Slz'
  $varPolicySetDefVarComment = '// Policy Set/Initiative Definition Parameter Variables'

  for ($count = 0; $count -lt $varPolicySetDefTextFile.Length; $count++) {
    $varLine = $varPolicySetDefTextFile[$count]

    <#line matching 'varCustomPolicySetDefinitionsArray' represents start of the json.
    Append this line to policyset defintion text files, as it will contain the jsons#>
    if ($varLine -match 'varCustomPolicySetDefinitionsArray') {
      Set-Content $parSlzPolicySetDefinitonTxtFile $varLine
      Set-Content $parAlzPolicySetDefinitonTxtFile $varLine
      continue
    }

    <# line matching the var 'policySetDefVarComment' indicates end of json.
    The arrayList containing json can be added to corresponding policyset defintion text files #>
    if ($varLine -match $varPolicySetDefVarComment) {
      if ($varSlzPolicySet.Count -gt 0) {
        $varPolicyParamVarName = Get-PolicySetParamVariableName $varSlzPolicySet
        [void]$varSlzPolicyParams.Add($varPolicyParamVarName)
        [void]$varSlzPolicySetList.Add($varSlzPolicySet)
        $varSlzPolicySet = @()
      }
      else {
        $varPolicyParamVarName = Get-PolicySetParamVariableName $varAlzPolicySet
        [void]$varAlzPolicyParams.Add($varPolicyParamVarName)
        [void]$varAlzPolicySetList.Add($varAlzPolicySet)
        $varAlzPolicySet = @()
      }
      #fetch the var name of the last parsed slz policy set and add the polic set to the slz policy set list

      #create the set definition text files, with the slz policy sets
      Add-SlzPolicySetDefinitionTxtFiles $varLine $varSlzPolicySetList

      if (Confirm-AddEndBracket $parSlzPolicySetDefinitonTxtFile) {
        Add-Content $parSlzPolicySetDefinitonTxtFile "]`r`n$varLine"
      }
      else {
        Add-Content $parSlzPolicySetDefinitonTxtFile "`r`n$varLine"
      }

      #create the set definition text files, with the alz policy sets
      Add-Content $parAlzPolicySetDefinitonTxtFile $varAlzPolicySetList
      if (Confirm-AddEndBracket $parAlzPolicySetDefinitonTxtFile) {
        Add-Content $parAlzPolicySetDefinitonTxtFile "]`r`n$varLine"
      }
      else {
        Add-Content $parAlzPolicySetDefinitonTxtFile "`r`n$varLine"
      }
      continue
    }

    <# check for line containing Policy Set Parameter Variables staring with 'var'
    and compare with vars in list 'slzPolicyParams' and 'alzPolicyParams', to add to the final bicep file #>
    if ($varLine -match 'var ()') {
      $varSlzPolicyParams | ForEach-Object {
        if ($_ -ne $null -and $varLine -match $_) {
          Add-Content $parSlzPolicySetDefinitonTxtFile $varLine
        }
      }
      $varAlzPolicyParams | ForEach-Object {
        if ($varLine -match $_) {
          Add-Content $parAlzPolicySetDefinitonTxtFile $varLine
        }
      }
      continue
    }

    <#line doesn't match 'nameString' and array slzPolicySet or alzPolicySet has size greater than zero,
    then we are parsing a slz policy set. Add the lines to array slzPolicySet and alzPolicySet#>
    if ($varLine -notmatch $varNameString) {
      if ($varSlzPolicySet.Count -gt 0) {
        $varSlzPolicySet += $varLine
        continue
      }
      elseif ($varAlzPolicySet.Count -gt 0) {
        $varAlzPolicySet += $varLine
        continue
      }
    }

    if ($varLine -match $varNameString) {
      <# line matches with a name string  and array alzPolicySet has size greater than zero,
      it indicates, the end of an alz policy set json. The array can be added to 'alzPolicySetList' and reset
      to contain next policy set #>
      if ($varAlzPolicySet.Count -gt 0 -And $varAlzPolicySet[$varAlzPolicySet.Count - 2] -match '}') {
        $varAlzPolicySet[$varAlzPolicySet.Count - 1] = ""

        <# parsing array 'alzPolicySet' to fetch Policy Set Parameter Variable
         and add to list 'alzPolicyParams' #>
        $varPolicyParamVarName = Get-PolicySetParamVariableName $varAlzPolicySet
        [void]$varAlzPolicyParams.Add($varPolicyParamVarName)
        [void]$varAlzPolicySetList.Add($varAlzPolicySet)
        $varAlzPolicySet = @()
      }
      <# line matches with a name string  and array slzPolicySet has size greater than zero,
      it indicates, the end of an slz policy set json. The array can be added to 'slzPolicySetList' and reset
      to contain next policy set #>
      if ($varSlzPolicySet.Count -gt 0 -And $varSlzPolicySet[$varSlzPolicySet.Count - 2] -match '}') {
        $varSlzPolicySet[$varSlzPolicySet.Count - 1] = ""

        <# parsing array 'slzPolicySet' to fetch Policy Set Parameter Variable
         and add to list 'slzPolicyParams' #>
        $varPolicyParamVarName = Get-PolicySetParamVariableName $varSlzPolicySet
        [void]$varSlzPolicyParams.Add($varPolicyParamVarName)
        [void]$varSlzPolicySetList.Add($varSlzPolicySet)
        $varSlzPolicySet = @()
      }
      $varPolicySetName = ("$varLine" | Select-String -Pattern $varPolicyNamePattern).Matches[0].Value
      <# fetch policysetname and check if its prefixed with 'SLZ'
      to consider the policy set for newly created policy SLZ set definition files #>
      if ($varPolicySetName.Substring(1, 3) -eq $varSlzPolicyNamePrefix) {
        if ($varSlzPolicySet.Count -eq 0) {
          $varSlzPolicySet = "{"
        }
        $varSlzPolicySet += $varLine
      }
      else {
        if ($varAlzPolicySet.Count -eq 0) {
          $varAlzPolicySet = "{"
        }
        $varAlzPolicySet += $varLine
      }
    }
  }
}

<#
.Description
Get the policy set parameter variable name from the policy set json
#>
function Get-PolicySetParamVariableName {
  param ($parPolicySet)
  $varDefinitionParametersString = 'definitionParameters:'
  $varParamPattern = 'var(.*)Parameters'

  foreach ($varLine in $parPolicySet) {
    if ($varLine -match $varDefinitionParametersString) {
      $varRegex = [Regex]::new($varParamPattern)
      $varMatch = $varRegex.Match($varLine)
      return $varMatch.Value
    }
  }
}

<#
.Description
Checks whether to add an end bracket to the policy set definition file
#>
function Confirm-AddEndBracket {
  param ($parPolicySetfilePath)
  $varPolicySetFileContent = Get-Content $parPolicySetfilePath
  #for the sceanario where there are no slz custom policies
  $varIterationCounter = $varPolicySetFileContent.Count
  if ($varIterationCounter -eq 1) {
    if ($varPolicySetFileContent[$varIterationCounter][-1] -eq "]") {
      return $false
    }
    else {
      return $true
    }
  }
  do {
    if ($varPolicySetFileContent[$varIterationCounter] -match '}') {
      return $true
    }

    if ($varPolicySetFileContent[$varIterationCounter] -match ']') {
      return $false
    }

    $varIterationCounter--;
  } while ($varIterationCounter -gt 0)
}

<#
.Description
Add slz policy set definition to slz policy set definition text file
#>
function Add-SlzPolicySetDefinitionTxtFiles {
  param ($parLine, $parSlzPolicySetList)
  $varSlzPolicySets = @()

  foreach ($varPolicySet in $parSlzPolicySetList) {
    $varSlzPolicySets += $varPolicySet
  }
  #add other slz policy sets to a different policy set definition file
  Add-Content $parSlzPolicySetDefinitonTxtFile $varSlzPolicySets
}

<#
.Description
Creating slz policy set defintion bicep file
#>
function New-CustomSlzPolicySetDefinitionBicepFile {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  # processing animation for attended run
  if ($parAttendedLogin) {
    $varDelay = 1000
    $varStartLeft = [Console]::CursorLeft
    $varStartTop = [Console]::CursorTop
    $varOriginalColor = [Console]::ForegroundColor
    $varLoadingChars = @('-', '\', '|', '/')
    $varPos = 0
  }

  $varSlzPolicyDefinitionsSetBicepInput = "$parSlzPolicySetDefinitonTxtFile"
  $varCustomSLZPolicyDefinitionsBicepFile = "$parDestRootPath/definitions/slz-CustomPolicySetDefinitions.bicep"
  $varKeepCopying = $true

  try {
    Set-Content -Path $parTempSLZPolicySetDefinitionOutput -Value "//`r`n// auto-generated-slz-policy-bicep-file by Cloud for Sovereignty team`r`n//"
    Get-Content $varCustomSLZPolicyDefinitionsBicepFile | ForEach-Object {
      if ($_ -match '<!--\s*slzCustomPolicySetDefinitionsReplacement(Start|End)\s*-->') {
        if ($_ -match '.+([Ss]tart)\s*-->') {
          $varKeepCopying = $false

          Add-Content -Path $parTempSLZPolicySetDefinitionOutput -Value "// start"
          # copy $varSlzPolicyDefinitionsSetBicepInput
          Get-Content $varSlzPolicyDefinitionsSetBicepInput | Add-Content -Path $parTempSLZPolicySetDefinitionOutput
          Add-Content -Path $parTempSLZPolicySetDefinitionOutput -Value "// end"

          if ($parAttendedLogin) {
            Flush_Output "[*] loading from auto-gen file..." $varDelay $varStartLeft $varStartTop $varOriginalColor
          }
        }
        elseif ($_ -match ".+([Ee]nd)\s*-->") {
          $varKeepCopying = $true
        }
      }
      else {
        # write line to $parTempSLZPolicySetDefinitionOutput
        if ($varKeepCopying) {
          Add-Content -Path $parTempSLZPolicySetDefinitionOutput -Value $_

          if ($parAttendedLogin) {
            $varPos = $varPos + 1
            $varLoadingCh = $varLoadingChars[$($varPos % $varLoadingChars.Length)]
            Flush_Output "[$varLoadingCh] loading from original file..." 0 $varStartLeft $varStartTop Blue
          }
        }
      }
    } #end of Foreach
    if ($parAttendedLogin) {
      [Console]::ForegroundColor = $varOriginalColor
    }
  }
  catch {
    Write-Error "Error in creating new policy/policy-set: $_.Exception.Message"
  }

  #replace $varDefaultandCustomSLZPolicyDefinitionsBicepFile with $parTempSLZPolicySetDefinitionOutput
  Copy-Item $parTempSLZPolicySetDefinitionOutput -Destination $varCustomSLZPolicyDefinitionsBicepFile -force
}

<#
.Description
Creating alz policyset defintion bicep file
#>
function New-AlzPolicySetDefinitionBicepFile {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  # processing animation for attended run
  if ($parAttendedLogin) {
    $varDelay = 1000
    $varStartLeft = [Console]::CursorLeft
    $varStartTop = [Console]::CursorTop
    $varOriginalColor = [Console]::ForegroundColor
    $varLoadingChars = @('-', '\', '|', '/')
    $varPos = 0
  }

  $alzPolicyDefinitionsSetBicepInput = "$parAlzPolicySetDefinitonTxtFile"
  $varAlzPolicyDefinitionsBicepFile = "$parDestRootPath/definitions/alzPolicySetDefinitions.bicep"
  $varKeepCopying = $true

  try {
    Set-Content -Path $parTempALZPolicySetDefinitionOutput -Value "//`r`n// auto-generated-slz-policy-bicep-file by Cloud for Sovereignty team`r`n//"
    Get-Content $varAlzPolicyDefinitionsBicepFile | ForEach-Object {
      if ($_ -match '<!--\s*alzDefaultPolicySetDefinitionsReplacement(Start|End)\s*-->') {
        if ($_ -match '.+([Ss]tart)\s*-->') {
          $varKeepCopying = $false

          Add-Content -Path $parTempALZPolicySetDefinitionOutput -Value "// start"
          # copy $alzPolicyDefinitionsSetBicepInput
          Get-Content $alzPolicyDefinitionsSetBicepInput | Add-Content -Path $parTempALZPolicySetDefinitionOutput
          Add-Content -Path $parTempALZPolicySetDefinitionOutput -Value "// end"

          if ($parAttendedLogin) {
            Flush_Output "[*] loading from auto-gen file..." $varDelay $varStartLeft $varStartTop $varOriginalColor
          }
        }
        elseif ($_ -match ".+([Ee]nd)\s*-->") {
          $varKeepCopying = $true
        }
      }
      else {
        # write line to $parTempALZPolicySetDefinitionOutput
        if ($varKeepCopying) {
          Add-Content -Path $parTempALZPolicySetDefinitionOutput -Value $_

          if ($parAttendedLogin) {
            $varPos = $varPos + 1
            $varLoadingCh = $varLoadingChars[$($varPos % $varLoadingChars.Length)]
            Flush_Output "[$varLoadingCh] loading from original file..." 0 $varStartLeft $varStartTop Blue
          }
        }
      }
    } #end of Foreach
    if ($parAttendedLogin) {
      Flush_Output "[*] Completed loading from original files and auto-gen files." 0 $varStartLeft $varStartTop Blue $true
      [Console]::ForegroundColor = $varOriginalColor
    }
  }
  catch {
    Write-Error "Error in creating new policy/policy-set: $_.Exception.Message"
  }

  #replace $varAlzPolicyDefinitionsBicepFile with $parTempALZPolicySetDefinitionOutput
  Copy-Item $parTempALZPolicySetDefinitionOutput -Destination $varAlzPolicyDefinitionsBicepFile -force
}

<#
.Description
Remove temp files created during the slz deployment
#>
function Remove-TempFile {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  Write-Information "Removing tempCustomPolicyDefinitions.bicep and slzTempCustomPolicySetDefinitions.bicep files" -InformationAction Continue
  Get-Item -Path ".\tempCustomPolicyDefinitions.bicep" | Remove-Item
  Get-Item -Path ".\slzTempCustomPolicySetDefinitions.bicep" | Remove-Item
  Get-Item -Path ".\alzTempPolicySetDefinitions.bicep" | Remove-Item
  Write-Information "Removed tempCustomPolicyDefinitions.bicep and slzTempCustomPolicySetDefinitions.bicep files" -InformationAction Continue
}

<#
.Description
Utility function to flush output to console
#>
function Flush_Output {
  param([String]$parMessage, [int]$parDelay, [int]$parStartLeft, [int]$parStartTop, [ConsoleColor]$parStartColor, [bool]$parNewLine = $false)

  $varCursorTop = [Console]::CursorTop
  [Console]::ForegroundColor = $parStartColor
  [Console]::CursorLeft = $parStartLeft
  [Console]::CursorTop = $parStartTop

  if ($parNewLine) {
    Write-Host $parMessage
  }
  else {
    Write-Host $parMessage -NoNewline
  }

  [Console]::SetCursorPosition(0, $varCursorTop)
  if ($parDelay -gt 0) {
    Start-Sleep -Milliseconds $parDelay
  }
}

Remove-ExistingPolicySetFiles
Copy-SlzCustomPolicyDefinitionsBicep
<# For slz custom policies #>
Write-Information ">>> Processing custom policy set definitions" -InformationAction Continue
Move-PolicySetDefinitions $parCustomPoliciesRootPath
Write-Information ">>> Processed and copied custom policy definition sets" -InformationAction Continue
<# Invoke ALZ Script - InvokePolicyToBicep to create files containing policy definition and policy set definition #>
Invoke-ALZScript
<# The function will create alz policy definition bicep file #>
New-AlzPolicyDefinitionsBicepFile
<# The function will create a file containing slz policies and a file for alz policies #>
New-SLZPolicySetDefinitonsBicepInputFiles
<# The function will create SLZ policy set definition bicep file #>
New-CustomSlzPolicySetDefinitionBicepFile
<# The function will create ALZ policy set definition bicep file #>
New-AlzPolicySetDefinitionBicepFile
Remove-TempFile
