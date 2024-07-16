# Using Existing Subscriptions

In some cases the user will not be able to use the SLZ to create subscriptions. This often happens for organizations that procure subscriptions through a partner or when an organization's policy requires the user to procure subscriptions through another internal team or process.

In either case, the lifecycle for subscriptions does not need to be managed by the SLZ and the SLZ can be configured to use existing subscriptions. In this case the user will still require the permissions described [during the setup steps](../05-Permissions-Tooling.md) as well as the [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner) permission within all subscriptions being used.

It is recommended for these subscriptions to follow the same naming convention as the SLZ deployed ones:
1. `{parDeploymentPrefix}-connectivity{parDeploymentSuffix}`
2. `{parDeploymentPrefix}-identity{parDeploymentSuffix}`
3. `{parDeploymentPrefix}-management{parDeploymentSuffix}`

Although any naming convention can be used. To configure the SLZ to use these subscriptions when deploying resources, update the parameters file with the following values:
1. `parConnectivitySubscriptionId`.value
   * The ID of the `{parDeploymentPrefix}-connectivity{parDeploymentSuffix}` subscription.
2. `parIdentitySubscriptionId`.value
   * The ID of the `{parDeploymentPrefix}-identity{parDeploymentSuffix}` subscription.
3. `parManagementSubscriptionId`.value
   * The ID of the `{parDeploymentPrefix}-management{parDeploymentSuffix}` subscription.

## Using Existing Resources

Occasionally, it is useful for the SLZ to also use existing resources that have been deployed alongside these existing subscriptions. Review the [using existing resources](./Using-Existing-Resources.md) doc for details about which resource have BYO support.

## Deployments in a Singular Subscription

While it is technically possible to use the same subscription ID for all 3 default subscriptions to effectively deploy the SLZ into one subscription, this is not a supported scenario and there may be unexpected conflicts such as the incorrect set of Azure policies influencing the resources.

### [Microsoft Legal Notice](../NOTICE.md)
