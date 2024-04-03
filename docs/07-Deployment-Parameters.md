# Update required parameters

Before deployment of the Sovereign Landing Zone, the `Required` parameters identified below must be reviewed. The parameter file contains defaults for some values as well as sample values for complex data structures.

  1. In the Sovereign Landing Zone repository, navigate to the `/orchestration/scripts/parameters` folder.

  2. Open `sovereignLandingZone.parameters.json` in a text editor.

  3. Review and update at least the required parameters in the `"value"`: `""` field. Reference [Parameter value descriptions](#parameter-value-descriptions) for guidance on the full parameters available.
     * The SLZ deployment script will prompt the user for required values that are missed, but it's recommended to put all values in the parameter file.

  4. Save the file.

## Parameter value descriptions

This section contains descriptions and accepted values for all parameters within the sovereignLandingZone.parameters.json file. The `Used By` column indicates which parameters are used for a specific deployment step. We recommend first time users review and update the parameters marked as `Required` and use the `all` deployment step.

 |    | Parameter           |Description    | Guidance, examples               | Used By |
 |----|---------------------|---------------|----------------------------------|---------|
 | 1  | `Required` parDeploymentPrefix | Prefix added to all Azure resources created by the SLZ. | 5 characters or less; can only contain letters, digits, '-', '.' or '_'. No other special characters supported. <br /> e.g.: slz | all, bootstrap, compliance, platform, dashboard |
 | 2  | `Required` parTopLevelManagementGroupName | The name of the top-level management group for the SLZ. | e.g.: Sovereign Landing Zone | all, bootstrap |
 | 3  | parDeploymentSuffix | Optional suffix that will be added to all Azure resources created by the the SLZ. Use a '-' at the start of the suffix value if a dash is needed. | 5 characters or less <br /> e.g. test1 | all, bootstrap, compliance, platform, dashboard |
 | 4  | parTopLevelManagementGroupParentId | Optional parent for Management Group hierarchy, used as intermediate root Management Group parent, if specified. If empty (default) will deploy beneath Tenant Root Management Group. | Sample Format - /providers/Microsoft.Management/managementGroups/{mgId} | all, bootstrap |
 | 5  | `Required` parSubscriptionBillingScope | The full resource ID of billing scope associated to the EA, MCA or MPA account you wish to create the subscription in. | Sample Format (EA): /providers/Microsoft.Billing/BillingAccounts/{BillingAccountId}/enrollmentAccounts/{EnrollmentAccountId}<br />Sample Format (MCA): /providers/Microsoft.Billing/billingAccounts/{BillingAccountId}<br />Sample Format (MPA): /providers/Microsoft.Billing/billingAccounts/{BillingAccountId}<br />etc. | all, bootstrap |
 | 6  | `Required` parCustomer | The name of the organization deploying the SLZ to brand the compliance dashboard appropriately. | 128 characters or less<br />e.g.: Contoso | all, dashboard |
 | 7  | `Required` parDeploymentLocation | Location used for deploying Azure resources. | Azure region to use for deployments. *If Confidential Computing is required for your region, please reference the [Confidential Computing](https://learn.microsoft.com/azure/confidential-computing/overview) page for the latest information on availability.*<br />e.g.: westeurope | all, platform, dashboard |
 | 8  | `Required` parAllowedLocations | Full list of Azure regions allowed by policy where resources can be deployed that should include at least the `parDeploymentLocation`. | An array of values (Azure regions). <br />e.g.: ["eastus2", "westeurope"] | all, compliance |
 | 9 | `Required` parAllowedLocationsForConfidentialComputing | Full list of Azure regions allowed by policy where Confidential computing resources can be deployed. This may be a completely different list from `parAllowedLocations`. | An array of values (Azure regions). <br />e.g.: ["eastus2", "westeurope"] | all, compliance |
 | 10 | parDeployDdosProtection | Toggles deployment of Azure DDOS protection. True to deploy, otherwise false. | true; false | all, platform |
 | 11 | parDeployHubNetwork | Toggles deployment of the hub VNET. True to deploy, otherwise false. | true; false | all, platform |
 | 12 | parEnableFirewall | Toggles deployment of Azure Firewall. True to deploy, otherwise false. | true; false | all, platform |
 | 13 | parUsePremiumFirewall | Toggles deployment of the Premium SKU for Azure Firewall and only used if `parEnableFirewall` is enabled. True to use Premium SKU, otherwise false. | true; false | all, platform |
 | 14 | parHubNetworkAddressPrefix | CIDR range for the hub VNET. | CIDR range | all, platform |
 | 15 | parAzureBastionSubnet | CIDR range for the Azure Bastion subnet. | CIDR range | all, platform |
 | 16 | parGatewaySubnet | CIDR range for the Gateway subnet. | CIDR range | all, platform |
 | 17 | parAzureFirewallSubnet | CIDR range for the Azure Firewall subnet. | CIDR range | all, platform |
 | 18 | parCustomSubnets | List of other subnets to deploy on the hub VNET and their CIDR ranges. | Sample Format: [{"name": "CustomSubnet1", "ipAddressRange": "xx.xx.xx.xx/xx"}, {"name": "CustomSubnet2", "ipAddressRange": "xx.xx.xx.xx/xx"}] | all, platform |
 | 19 | parLogRetentionInDays | Length of time, in days, to retain log files with usage enforced by ALZ policies. | Number of days <br />e.g.: 365 | all, compliance, platform |
 | 20 | parManagementSubscriptionId | Optional management subscription ID when using an existing subscription. | Azure Subscription Id<br />e.g.: /providers/Microsoft.Management/managementGroups/slz-platform-management1  | bootstrap, platform, dashboard |
 | 21 | parIdentitySubscriptionId | Optional identity subscription ID when using an existing subscription. | Azure Subscription Id<br />e.g.: /providers/Microsoft.Management/managementGroups/slz-platform-identity1 | bootstrap, platform |
 | 22 | parConnectivitySubscriptionId | Optional connectivity subscription ID when using an existing subscription. | Azure Subscription Id<br />e.g.: /providers/Microsoft.Management/managementGroups/slz-platform-connectivity1 | bootstrap, platform |
 | 23 | parDdosProtectionResourceId | Optional resource ID for an existing DDoS plan with usage enforced by ALZ policies. | DDoS Plan Resource Id<br />e.g.:/subscriptions/{subId}/resourceGroups/{rgId}/providers/Microsoft.Network/ddosProtectionPlans/slz-ddos-plan-westus21 | platform |
 | 24 | parLogAnalyticsWorkspaceId | Optional resource ID for an existing Log Analytics Workspace with usage enforced by ALZ policies. | Log Analytics Workspace Resource Id<br />e.g.: /subscriptions/{subId}/resourceGroups/{rgId}/providers/Microsoft.OperationalInsights/workspaces/slz-log-analytics-westus21 | compliance |
 | 25 | parRequireOwnerRolePermission | Set this to true if any policies in the initiative include a modify effect. | true; false | all, compliance |
 | 26 | parPolicyExemptions | Optional list of policy exemptions. | Sample Format: <br /> <br /> [{ <br /> "parPolicyExemptionManagementGroup":`value`, <br /> "parPolicyAssignmentName":`value`, <br /> "parPolicyAssignmentScopeName":`value`, <br /> "parPolicyDefinitionReferenceIds":`[]`, <br /> "parPolicyExemptionName":`value`, <br /> "parPolicyExemptionDisplayName":`value`, <br /> "parPolicyExemptionDescription":`value` <br /> }] <br /> <br />`parPolicyExemptionManagementGroup` - Management group being exempted from the assignment scope, e.g.: slz-landingzones-confidential-corp <br /> `parPolicyAssignmentName` - Name of the original policy assignment, e.g.: Deploy-SLZ-Root <br /> `parPolicyAssignmentScopeName` - Top-level management group where policy was assigned, e.g.: slz<br /> `parPolicyDefinitionReferenceIds` - Array of reference IDs of the policies being exempted, e.g.: "['AllowedLocation']" <br /> `parPolicyExemptionName` - Customized name for exemption, e.g.: Disable-locations <br /> `parPolicyExemptionDisplayName` - Human readable customized name for exemption, e.g.: Disable Locations from Scope <br /> `parPolicyExemptionDescription` - Description of the exemption, e.g.: Disabling location restrictions defined on the top-level management group to the slz-landingzones-confidential-corp MG | policyexemptions |
 | 27 | parExpressRouteGatewayConfig | Optional configuration options for the ExpressRoute Gateway. | ExpressRoute Gateway Configuration<br /><br />Sample Format:<br />{<br />"sku": "standard",<br />"vpntype": "RouteBased",<br />"vpnGatewayGeneration": null,<br />"enableBgp": false,<br />"activeActive": false,<br />"enableBgpRouteTranslationForNat": false,<br />"enableDnsForwarding": false,<br />"asn": 65515,<br />"bgpPeeringAddress": "",<br />"peerWeight": 5<br />} | all, platform |
 | 28 | parVpnGatewayConfig | Optional configuration options for the VPN Gateway. | VPN Gateway Configuration<br /><br />Sample Format:<br />{<br />"sku": "VpnGw1",<br />"vpntype": "RouteBased",<br />"generation": "Generation1",<br />"enableBgp": false,<br />"activeActive": false,<br />"enableBgpRouteTranslationForNat": false,<br />"enableDnsForwarding": false,<br />"asn": 65515,<br />"bgpPeeringAddress": "",<br />"peerWeight": 5<br />} | all, platform |
 | 29 | parDeployBastion | Toggles deployment of Azure Bastion. True to deploy, otherwise false. | true; false | all, platform |
 | 30 | parLandingZoneMgChildren | Optional array of child management groups to deploy under the SLZ Landing Zones management group. | Sample Format: [{"id": "mymg", "displayName": "My MG display name"}] | all, bootstrap |
 | 31 | parDeployAlzDefaultPolicies | Toggles assignment of ALZ policies. True to deploy, otherwise false. | true; false | all, compliance |
 | 32 | parAutomationAccountName | Optional resource name for an existing Azure Automation account with usage enforced by ALZ policies. | Automation Account name<br />e.g.: slz-managed-identity-westus21 | all, compliance |
 | 33 | parPrivateDnsResourceGroupId | Optional resource ID of the Azure Resource Group that contains the Private DNS Zones with usage enforced by ALZ policies. | Resource Group ID<br />e.g.: /subscriptions/{subId}/resourceGroups/slz-rg-hub-network-westus2 | all, compliance |
 | 34 | parMsDefenderForCloudEmailSecurityContact | An e-mail address that you want Microsoft Defender for Cloud alerts to be sent to. | Email address | all, compliance |
 | 35 | parBastionOutboundSshRdpPorts | Array of outbound destination ports and ranges for Azure Bastion. | An array of values (ports)<br />e.g.: ["22", "3389"] | all, platform |
 | 36 | parInvokePolicyScanSync | Toggles executing the policy scan in synchronous mode. True to run policy scan in synchronous mode, False for asynchronous. When set to false, policy remediation needs to be manually triggered once the scan is complete. Note that when policy scan is run asynchronously, there isn't a way to track its progress. | true; false | all, compliance |
 | 37 | parInvokePolicyRemediationSync | Toggles executing the policy scan in synchronous mode. True to run policy remediation in synchronous mode, False for asynchronous. | true; false | all, compliance |
 | 38 | parPolicyEffect | The policy effect used in all assignments for the Sovereignty Baseline policy initiatives. | Choose one: "Audit", "Deny", "Disabled" | all, compliance |
 | 39 | parDeployLogAnalyticsWorkspace | Toggles deployment of Log Analytics Workspace. True to deploy, otherwise false. | true; false | all, platform |
 | 40 | parCustomerPolicySets | Customer specified policy assignments to the top-level management group of the SLZ. No parameters are supported as part of the assignment. | Name field can only be a letter, digit, '-', '.' or '_' and cannot have any trailing special character.<br />See the SLZ parameter file for a sample configuration. | all, compliance |
 | 41 | parTags | Tags that will be assigned to subscription and resources created by this deployment script. | See the SLZ parameter file for a sample configuration. | all, bootstrap, platform, and dashboard |

## Next step

[Deploy the Sovereign Landing Zone](08-Deploy-SLZ.md)

### [Microsoft Legal Notice](./NOTICE.md)
