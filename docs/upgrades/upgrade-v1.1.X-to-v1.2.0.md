# Upgrading from v1.1.X to v1.2.0

## Upgrading PowerShell, Bicep, and AZ Modules

There are no required upgrades to PowerShell, Bicep, or the AZ modules as part of this release.

Refer the the [tooling requirements](../05-Permissions-Tooling.md#tooling-required) for details on what is currently required.

## Upgrading Default Policies

Users that have enabled the `parDeployAlzDefaultPolicies` parameter will see several new policies rolled out with this release. Refer to the [Policy Refresh H2 FY24](https://github.com/Azure/Enterprise-Scale/wiki/Whats-new#-policy-refresh-h2-fy24) for full details.

## Deprecated Parameters

The following parameters will still work, but will be removed in the v2.0.0 release.

* `parAzureBastionSubnet`
* `parGatewaySubnet`
* `parAzureFirewallSubnet`

These are being rolled into the `parCustomSubnets` parameter. For instance, if you had a config that looked like this in v1.1.X:

```
    "parAzureBastionSubnet": {
      "type": "string",
      "usedBy": "all and platform",
      "defaultValue": "10.20.15.0/24",
      "value": "10.20.15.0/24",
      "description": "CIDR range for the Azure Bastion subnet. This parameter is deprecated soon, please use parameter parCustomSubnets instead."
    },
    "parGatewaySubnet": {
      "type": "string",
      "usedBy": "all and platform",
      "defaultValue": "10.20.252.0/24",
      "value": "10.20.252.0/24",
      "description": "CIDR range for the Gateway subnet. This parameter is deprecated soon, please use parameter parCustomSubnets instead."
    },
    "parAzureFirewallSubnet": {
      "type": "string",
      "usedBy": "all and platform",
      "defaultValue": "10.20.254.0/24",
      "value": "10.20.254.0/24",
      "description": "CIDR range for the Azure Firewall subnet. This parameter is deprecated soon, please use parameter parCustomSubnets instead."
    }
```

This would be moved into the `parCustomSubnets` parameter for v1.2.0 and would now look like this:

```
    "parCustomSubnets": {
      "type": "array",
      "usedBy": "all and platform",
      "sampleValue": [],
      "defaultValue": [],
      "value": [{
        "name": "AzureBastionSubnet",
        "ipAddressRange": "10.20.15.0/24"
      }, {
        "name": "GatewaySubnet",
        "ipAddressRange": "10.20.252.0/24"
      }, {
        "name": "AzureFirewallSubnet",
        "ipAddressRange": "10.20.254.0/24"
      }],
      "description": "List of other subnets to deploy on the hub VNET and their CIDR ranges."
    }
```

## Updated Parameters

The `parCustomSubnets` parameter has been expanded upon to handle all subnets in the hub VNET but also to optionally handle the assignment of Network Security Groups and Route Tables. This can be done by specifying these values in the subnet object. For instance a v1.1.X version would look like this:


```
"value": [{
  "name": "ServerSubnet",
  "ipAddressRange": "10.20.20.0/24"
}]
```

And a v1.2.0 version would look like this:

```
"value": [{
  "name": "ServerSubnet",
  "ipAddressRange": "10.20.20.0/24",
  "networkSecurityGroupId": "/subscriptions/{subId}/resourceGroups/{rgId}/providers/Microsoft.Network/networkSecurityGroups/{nsgId}",
  "routeTableId": "/subscriptions/{subId}/resourceGroups/{rgId}/providers/Microsoft.Network/routeTables/{rtId}"
}]
```

It is common to create an SLZ deployment without having NSGs or Route Tables specified so that the connectivity subscription and resource groups get created, then create these resources post-deployment and update the `parCustomSubnets` parameter to ensure they get assigned the next time the SLZ deployment script is ran.

Refer to the [deployment parameters](../07-Deployment-Parameters.md) for full details about the parameter schema.

## New Parameters

### parAzFirewallPoliciesEnabled

The `parAzFirewallPoliciesEnabled` parameter has been added to toggle configuration capabilities with the firewall policies. When set to `true`, the SLZ will oversee the policy configuration and will reset it to the null configuration on every `platform` deployment.

Organizations who need to customize the firewall policies should set `parAzFirewallPoliciesEnabled` to `false` to ensure the upgrade process doesn't revert any custom modifications they have previously made.

### parAzFirewallCustomPublicIps

The `parAzFirewallCustomPublicIps` parameter has been added to support highly-available firewall deployments. When set, the firewall will be updated to use all of the public IPs specified in this parameter.

Organizations who need to ensure they have a highly-available firewall deployment should set the `parAzFirewallCustomPublicIps` parameter. Refer to the [deployment parameters](../07-Deployment-Parameters.md) for full details about the parameter schema.

### [Microsoft Legal Notice](../NOTICE.md)
