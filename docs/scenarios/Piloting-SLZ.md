# Sovereign Landing Zone Pilots

The numbered getting started docs are intended to overview the steps that would be required for a production deployment of the SLZ. However, this often requires greater permissions and has a higher cost than what an organization may be willing to spend while they are conducting a pilot.

## Reduced Permissions

**Note** The `Confirm-SovereignLandingZonePrerequisites.ps1` script will not attempt to automatically elevate Azure permissions when using a child management group as the top-level.

Reference the production deployment [permission setup](../05-Permissions-Tooling.md) for the recommended steps. For pilot deployments, there are a few additional recommendations.

1. **Use existing subscriptions**
   * This means the identity being used to deploy the SLZ does not need broad permissions to create subscriptions, but can be given a set of existing subscriptions to use.
   * See the [using existing subscriptions](./Using-Existing-Subscriptions.md) doc for more details.
2. **Use a child management group as the top-level**
   * By default the SLZ will attempt to create a top-level management group to store all resources at the [tenant root group](https://learn.microsoft.com/azure/governance/management-groups/overview#root-management-group-for-each-directory) level. This is a very board permission that may allow the identity to alter any resource within the tenant.
   * Instead, it is recommended to create a new management group at some other level and assign the broad permissions there so the identity deploying the SLZ will have no ability to modify existing Azure resources.
   * The SLZ can be configured to deploy within this new management group via the `parTopLevelManagementGroupParentId` parameter. View our [parameter guidance](../07-Deployment-Parameters.md) doc for further details on configuring the SLZ.
   * **Note** Using the `parTopLevelManagementGroupParentId` parameter to separate multiple SLZ deployments is also the recommended approach for managing multiple side-by-side deployments as is needed to meet development, testing, and isolation requirements.

## Reduced Resources

It is crucial to be conscientious of the cost implications when conducting a pilot. It is worth considering if the following resources are required for the pilot and making the following changes in the parameter file to disable them if they are not:

1. [Azure DDos Protection](https://learn.microsoft.com/azure/ddos-protection/ddos-protection-overview) - This can be disabled by setting the `parDeployDdosProtection` value to `false`
2. [Azure Firewall](https://learn.microsoft.com/azure/firewall/overview) - This can be disabled by setting the `parEnableFirewall` value to `false`.
   * If Azure Firewall is needed, consider using the basic SKU by setting `parUsePremiumFirewall` to `false`
3. [Azure Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview) - This can be disabled by setting the `parDeployBastion` value to `false`.

### [Microsoft Legal Notice](../NOTICE.md)
