# Deploying the SLZ in a Pipeline

While the SLZ deployment process works well to be executed manually, it can also easily be executed in a pipeline. This will require that a [service principal (SPN)](https://learn.microsoft.com/azure/active-directory/develop/howto-create-service-principal-portal) has been granted the same [required permissions](../05-Permissions-Tooling.md) that a user must have, and that the SPN is bound to a [service connection](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#azure-resource-manager-service-connection) and used during the [pipeline execution](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#use-a-service-connection).  There are a few considerations when doing this:

## Running in Unattended Mode

When the SLZ deployment script is executed, it will check for dependencies and prompt the user for information. This is not suitable for pipeline deployments where it is not possible to interact with the script. Pipelines can execute the same flow without being prompted by running the script in unattended mode:

```
.\New-SovereignLandingZone.ps1 -parDeployment all -parAttendedLogin $false
```

Unattended mode will expect that an identity has already been logged in and that their AZ context is setup to the appropriate tenant.

## Multiple Parameter Files

When the SLZ deployment script is executed, it will reference the [parameter file](../../orchestration/scripts/parameters/sovereignLandingZone.parameters.json) for all values required for the deployment. This is not suitable for pipeline deployments where you may not want to have the parameter file checked into the same repository as the code, or when you want to use manage multiple deployments. The deployment script can be directed to find the parameter file at a different path:

```
.\New-SovereignLandingZone.ps1 -parDeployment all -parParametersFilePath path/to/parameter/file.json
```

## Individual Deployment Steps

The SLZ deployment script has [multiple steps](../03-Deployment-Overview.md) that can be deployed individually. It is useful to run a singular deployment step to speed up the deployment process when the change that needs to be deployed is limited to one deployment step. For instance, adding new custom policies does not require redeploying the entire platform, but instead can be executed by setting the appropriate `parDeployment` CLI parameter:

```
.\New-SovereignLandingZone.ps1 -parDeployment compliance
```

Or by running:

```
. .\New-Compliance.ps1
New-Compliance -parParametersFilePath path/to/parameter/file.json
```

These are the deployment steps:

|Step Name|parDeployment value|Individual Script|Description|
|---------|-------------------|-----------------|-----------|
|Bootstrap|bootstrap|New-Bootstrap.ps1|Deploys the management groups and subscriptions|
|Platform|platform|New-Platform.ps1|Deploys all Azure resources|
|Compliance|compliance|New-Compliance.ps1|Deploys and assigns all Azure policies|
|Dashboard|dashboard|New-Dashboard.ps1|Deploys the compliance dashboard|
|Policy Exemptions|policyexemption|New-PolicyExemption.ps1|Deploys all custom policy exemptions|
|Policy Remediations|policyremediation|New-PolicyRemediation.ps1|Executes all policy remediations and scans|

## Required Parameters

These deployment steps also have additional required parameters as the SLZ deployment script will not attempt to query an environment to determine these values. An individual deployment step will also have the required parameters of the deployment steps that are before it. For instance the `Compliance` step will also need the `Platform` step's required parameters. Every execution of the SLZ will log key resources including these required parameters to a CSV file. These log files will be stored in `/orchestration/scripts/outputs` and will be timestamped with the deployment name in the title.

|Step Name|Additional Required Parameters|
|---------|-------------------|
|Bootstrap|N/A|
|Platform|`parManagementSubscriptionId`<br />`parIdentitySubscriptionId`<br />`parConnectivitySubscriptionId`|
|Compliance|`parLogAnalyticsWorkspaceId`<br />`parAutomationAccountName`<br />`parPrivateDnsResourceGroupId`<br />`parDdosProtectionResourceId` (if `parDeployDdosProtection` is `true`)|
|Dashboard|N/A|
|Policy Exemptions|N/A|
|Policy Remediations|N/A|

## Pipeline Templates

There may be some issues invoking the SLZ deployment scripts from a BASH task. Instead, it is recommended to use the `AzurePowerShell@5` task to invoke the scripts such as through the following example:

```
- task: AzurePowerShell@5
  inputs:
    azureSubscription: ${{ parameters.SERVICE_CONNECTION }}
    azurePowerShellVersion: LatestVersion
    ScriptType: inlineScript
    Inline: |
       cd orchestration\scripts\
       ./New-SovereignLandingZone.ps1 -parAttendedLogin 0 -parDeployment all
```

Where the `SERVICE_CONNECTION` parameter is the previously setup service connection to be used during [pipeline execution](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#use-a-service-connection).

### [Microsoft Legal Notice](../NOTICE.md)
