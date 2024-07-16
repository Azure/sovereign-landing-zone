# Customize baseline policies

Once the SLZ is deployed, the management group structure, subscriptions, and the [Sovereignty Baseline policy initiatives](Sovereignty-Baseline-Policy-Initiatives.md) will be in place. While the baseline can be configured, it may be necessary to apply additional policies to address local laws and regulations. Review the [Microsoft Cloud for Sovereignty policy portfolio](https://github.com/Azure/cloud-for-sovereignty-policy-portfolio) for policies that support specific regulations, or follow the below steps to deploy your own policies alongside the SLZ.

## Assigning existing initiatives

The SLZ allows for both builtin and custom initiatives to be assigned during deployment at a specified scope and with custom parameters. This option is most useful for the following cases:

1. When the policy initiative definitions are common across multiple SLZ deployments and need to be created at the tenant root group.
2. When the policy initiative definition needs to be tested and validated before an SLZ deployment.
3. When there are variable parameters could be needed during assignment.

Many users may find this option to be the most flexible.

This capability can be used in a deployment by setting the `parCustomerPolicySets` value in the parameter file. Review the parameter file or the [Deployment Parameters](../07-Deployment-Parameters.md) for additional details about the structure for this object.

## Customization step by step

The SLZ allows for custom policy initiatives to be deployed and within the standard management group scopes. This option is most useful for the following cases:

1. When the policy initiative definitions are unique to an individual SLZ deployment.
2. When the policy initiative definition lifecycle should be the same as the SLZ deployment.
3. When there are no variable parameters needed during assignment.

This capability can be used in a deployment through the following:

1. Navigate to the custom policy definitions located in `/custom/policies/definitions` in your version of the GitHub repository.
2. Each definition corresponds to one of the default management group scopes deployed as part of the SLZ management group hierarchy:
    * `slzConfidentialCustom.json` -> Confidential Corp and Confidential Online Management Groups
    * `slzConnectivityCustom.json` -> Connectivity Management Group
    * `slzCorpCustom.json` -> Corp and Confidential Corp Management Groups
    * `slzDecommissionedCustom.json` -> Decommissioned Management Group
    * `slzGlobalCustom.json` -> The Top-Level Management Group
    * `slzIdentityCustom.json` -> Identity Management Group
    * `slzLandingZoneCustom.json` -> Landing Zones Management Group
    * `slzManagementCustom.json` -> Management Management Group
    * `slzOnlineCustom.json` -> Online and Confidential Online Management Groups
    * `slzPlatformCustom.json` -> Platform Management Group
    * `slzSandboxCustom.json` -> Sandbox Management Group
3. Select the file for management group scope that you want custom policies to apply to. For instance, if you want to apply custom policies to all application workloads then select `slzLandingZoneCustom.json`
4. Custom policies policies can be added to the selected custom initiative by updating the `parameters`, `policyDefinitions`, and `policyDefinitionGroups` as described by the [initiative definition structure](https://learn.microsoft.com/azure/governance/policy/concepts/initiative-definition-structure). Do NOT edit the `policyType`, `id`, `type`, or `name` fields.
5. Grouping policies together on the [SLZ dashboard](./Extending-Compliance-Dashboard.md) is accomplished by adding `so.` to the beginning of the policy definition group name, but any name can be used. The documentation for the [policy set definition group structure](https://learn.microsoft.com/azure/governance/policy/concepts/initiative-definition-structure#policy-definition-groups) describes the group structure further. An excerpt of a valid policy group name can be found below:
```
    {
        "name": "so.NIST_SP_800-171_R2",
        "category": "Regulatory Compliance",
        "description": "NIST 800-171 rev2"
    }
```     
6. Passing values to the custom policy definitions is not currently supported. You can set default values in the definition file or in the assignment file (located in the `/custom/policies/assignments` folder) but you cannot pass in values from the orchestration script at this time. Documentation on the assignment structure and how to set parameters is located [here](https://learn.microsoft.com/azure/governance/policy/concepts/assignment-structure)
7. Once you have added the custom policies to the policy set file, you only need to save the file and run `.\New-SovereignLandingZone.ps1` with either the `all`, or `compliance` deployment step and your custom policies will be added and assigned to the appropriate management group scopes.
8. If you need to change a policy effect, you will need to make that change to the above definitions and redeploy the SLZ as above. For documentation on how to set a policy effect please review the documentation [here](https://learn.microsoft.com/azure/governance/policy/concepts/effects)

**Note** Custom policies will need to fit with the [Azure policy and policy rule limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-policy-limits) otherwise Azure will not create the definitions.

## Using Compliance Outside an SLZ Deployment

For ALZ customers, it is recommended to deploy the relevant Azure Policy and Initiative definitions and assignments using the [ALZ recommended path](https://github.com/Azure/ALZ-Bicep/wiki/PolicyDeepDive).

For customers that aren't using the ALZ or the SLZ, they may still use the SLZ compliance modules to deploy the relevant policies. To use these modules, the customer landing zone must still have the same management group structure and IDs as an SLZ deployment would create. Specifically, the Management Group parent and child IDs must be:

* `[PREFIX][SUFFIX]`
  * `[PREFIX]`-decommissioned`[SUFFIX]`
  * `[PREFIX]`-landingzones`[SUFFIX]`
    * `[PREFIX]`-landingzones-confidentialcorp`[SUFFIX]`
    * `[PREFIX]`-landingzones-confidentialonline`[SUFFIX]`
    * `[PREFIX]`-landingzones-corp`[SUFFIX]`
    * `[PREFIX]`-landingzones-online`[SUFFIX]`
  * `[PREFIX]`-platform`[SUFFIX]`
    * `[PREFIX]`-platform-connectivity`[SUFFIX]`
    * `[PREFIX]`-platform-identity`[SUFFIX]`
    * `[PREFIX]`-platform-management`[SUFFIX]`
  * `[PREFIX]`-sandbox`[SUFFIX]`

Then the [compliance deployment step](./Pipeline-Deployments.md#individual-deployment-steps) can be executed directly to create the relevant definitions and assignments, provided a valid parameter file is created with the required parameters specified in the previous link.

### [Microsoft Legal Notice](../NOTICE.md)
