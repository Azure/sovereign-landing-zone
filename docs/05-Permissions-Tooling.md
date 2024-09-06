# Permissions and Tooling

This article will walk through the required Azure permissions, setting up your local workspace, and the validation steps needed for a successful deployment of the Sovereign Landing Zone.

## Permissions

The account or service principal used to deploy the SLZ must have both of the following:

1. Ability to create subscriptions programmatically
   * The [Create Azure subscriptions programmatically](https://learn.microsoft.com/azure/cost-management-billing/manage/programmatically-create-subscription) documentation describes the types of Azure agreements that have REST APIs that will enable automatic subscription creation.
   * This document also provides links to the permissions required each Azure agreement type. The agreement type can be found in the [Cost Management + Billing](https://learn.microsoft.com/azure/cost-management-billing/manage/view-all-accounts#check-the-type-of-your-account) blade in the portal.
   * Bring-Your-Own subscriptions options could be most suitable for other types of Azure agreements or internal processes that necessitate a manual subscription creation process be used. More details can be found in our [additional setup steps](scenarios/Using-Existing-Subscriptions.md) doc.
2. Azure permissions to create management groups, Azure resources, and manage policies.
   * For smaller organizations organizations or ones that are new to Azure, [Global Administrator](https://learn.microsoft.com/azure/active-directory/roles/permissions-reference#global-administrator) permissions with [elevated Azure permissions](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) will provide sufficient access.
     * These may not be reasonable permissions to have within many organizations.
   * Otherwise, the management group permissions will need to be either [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner), [Contributor](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#contributor), or [Management Group Contributor](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#management-group-contributor) at either the [Tenant Root Group](https://learn.microsoft.com/azure/governance/management-groups/overview#hierarchy-of-management-groups-and-subscriptions) or the child management group being deployed within.
     * These broad permissions are necessary to deploy all types of Azure resources that the SLZ will attempt to create. The general owner or contributor roles are recommended over using a set of resource specific owner or contributor roles because the SLZ deploys a wide spectrum of Azure resources.
     * **Note** this is a very broad set of permissions and should be given to only the identities being used to deploy the SLZ. These broad permissions are needed to fully deploy all resources within the SLZ environment, but they should not be needed by operators and engineers working within a deployed SLZ. Review the documentation around [Azure identity and access management](https://learn.microsoft.com/azure/security/fundamentals/identity-management-best-practices) for best practices.
   * And the policy management permissions will need to be either [Security Admin](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#security-admin) or [Resource Policy Contributor](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#resource-policy-contributor) if the above [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner) permission is not provided.

## Tooling (`Required`)

The following local tooling must be installed to deploy the SLZ:
* PowerShell
  * At least version 7.0
* Azure CLI
  * At least version 2.51.0
* Azure Bicep
  * At least version 0.20.0
* Azure PowerShell
  * At least version 10.0.0

### PowerShell

PowerShell is a cross-platform task automation solution made up of a command-line shell, a scripting language, and a configuration management framework that runs on Windows, Linux, and macOS. You should use your organization's recommended installation and upgrade process for PowerShell, or [download and upgrade](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) it through Microsoft's recommended process.

Some machines will require upgrading PowerShell.

### Azure CLI

The Azure Command-Line Interface (CLI) is a cross-platform command-line tool to connect to Azure and execute administrative commands on Azure resources. You should use your organization's recommended installation and upgrade process for the Azure CLI, or [download and upgrade](https://learn.microsoft.com/cli/azure/install-azure-cli) it through Microsoft's recommended process.

Most machines will require installing the Azure CLI.

### Azure Bicep

Bicep is a domain-specific language (DSL) that uses declarative syntax to deploy Azure resources. You should use your organization's recommended installation and upgrade process for the Azure Bicep, or [download and upgrade](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install#azure-cli) it through Microsoft's recommended process.

Most machines will require installing Azure Bicep. You may run into upgrade issues if you have multiple versions of Azure Bicep installed so the [troubleshooting problems with Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/installation-troubleshoot#multiple-versions-of-bicep-cli-installed) installation doc may be useful.

### Azure PowerShell

Azure PowerShell is a set of cmdlets for managing Azure resources directly from PowerShell. Azure PowerShell is designed to make it easy to learn and get started with, but provides powerful features for automation. You should use your organization's recommended installation and upgrade process for Azure PowerShell, or [download and upgrade](https://learn.microsoft.com/powershell/azure/install-azure-powershell?view=azps-10.4.1) it through Microsoft's recommended process.

Most machines will require upgrading or installing the Azure PowerShell module.

## Validation

The [Confirm-SovereignLandingZonePrerequisites.ps1](../orchestration/scripts/Confirm-SovereignLandingZonePrerequisites.ps1) will validate that all the necessary prerequisites are in place to deploy the SLZ including both Azure permissions and local tooling.

This script *will check the versions* of the required tooling and will recommend upgrades but the user must manually install or upgrade the required tooling. The script will provide the same links found on this page to install the tools that are missing or out of date.

This script *will attempt to elevate your permissions* if required for a [tenant root group](https://learn.microsoft.com/azure/governance/management-groups/overview#root-management-group-for-each-directory) level deployment, which is necessary for accounts that are [Global Admins](https://learn.microsoft.com/azure/active-directory/roles/permissions-reference#global-administrator) and need Azure permissions.

1. In your version of the GitHub repository, navigate to `/orchestration/scripts`.
2. Run the `Confirm-SovereignLandingZonePrerequisites.ps1` script.
   * If you do not want your permissions elevated or do not need a tenant root group deployment, instead run:
   
```./Confirm-SovereignLandingZonePrerequisites.ps1 -parIsSLZDeployedAtTenantRoot $false```

You may need to update the PowerShell [execution policy](https://learn.microsoft.com/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.3) depending on your method of downloading the SLZ. You should use your organization's recommended PowerShell execution policy settings, or work with your organization's security team to determine the appropriate [execution policy](https://learn.microsoft.com/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.3) and [code signing](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_signing?view=powershell-7.3) settings to use.

If the script runs successfully, then all prerequisites are met, and you may move to the next step.

## Next step

**For new deployments** or to **update existing deployments**, proceed to [configure the parameters required for the SLZ deployment](07-Deployment-Parameters.md).

If you are an **existing SLZ Preview customer** (most users will not be) and would like to upgrade to the latest version, please follow the instructions in [Upgrade Existing SLZ Preview.](06-Upgrade-Existing-SLZ-Preview.md)

### [Microsoft Legal Notice](./NOTICE.md)
