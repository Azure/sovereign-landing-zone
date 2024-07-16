# Using Existing Resources

The SLZ deployment orchestration supports a Bring-Your-Own (BYO) model for a variety of resources. For BYO resources, there are a few common cases where this is useful:

1. When a previously deployed resource should be used by the SLZ.
2. When the resource configuration lifecycle is different from the SLZ configuration lifecycle.
    * Such as when a networking team would need to make changes to an NSG without wanting to redeploy the entire platform.
3. When a resource that was originally deployed by the SLZ should no longer be managed by the SLZ.
    * This is most common when the SLZ redeployment will attempt to reset a resource to a vanilla state even if post-deployment modifications are desired to be maintained.
4. When running a specific deployment step, the SLZ will expect dependent resources are already created and loaded into the parameter file. See the [pipeline deployment](./Pipeline-Deployments.md) doc for further details.

There is a dedicated doc for [BYO subscriptions](./Using-Existing-Subscriptions.md). The following parameters enable the usage of BYO resources:

|Parameter|Usage|
|---------|-------------------|
|`parTopLevelManagementGroupParentId`|Used by the SLZ to specify the management group to create the deployment under.|
|`parLogAnalyticsWorkspaceId`|Used by the ALZ Policies to enforce usage of an existing Log Analytics Workspace for diagnostic logging. Only used if `parDeployLogAnalyticsWorkspace` and `parDeployAlzDefaultPolicies` are `true`, or required for the individual deployment step.|
|`parAutomationAccountName`|Used by the ALZ Policies to enforce usage of an existing Automation Account for workflow automation. Only used if `parDeployAlzDefaultPolicies` is `true`, or required for the individual deployment step.|
|`parPrivateDnsResourceGroupId`|Used by the ALZ Policies to enforce usage of an existing Resource Group for hosting private DNS resources. Only used if `parDeployAlzDefaultPolicies` is `true`, or required for the individual deployment step.|
|`parDdosProtectionResourceId`|Used by the ALZ Policies to enforce usage of an existing DDOS protection plan for network protection. Only used if `parDeployDdosProtection` and `parDeployAlzDefaultPolicies` are `true`,  or required for the individual deployment step.|
|`parAzFirewallCustomPublicIps`|Used by the SLZ to specify the public IPs to be used by the firewall. Only used if `parEnableFirewall` is `true`.|
|`parCustomSubnets[].networkSecurityGroupId`|Used by the SLZ to specify the NSG that should be assigned to the subnet. Only used if `parDeployHubNetwork` is `true`.|
|`parCustomSubnets[].routeTableId`|Used by the SLZ to specify the route table that should be assigned to the subnet. Only used if `parDeployHubNetwork` is `true`.|

Reference the [pipeline deployment](./Pipeline-Deployments.md#required-parameters) doc for further details about how to find appropriate values in the logs for these additional required parameters.

### [Microsoft Legal Notice](../NOTICE.md)
