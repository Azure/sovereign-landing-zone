# Customize baseline policies

Once the SLZ is deployed, the management group structure, subscriptions, and the [Sovereignty Baseline policy initiatives](Sovereignty-Baseline-Policy-Initiatives.md) will be in place. While the baseline can be configured, it may be necessary to apply additional policies to address local laws and regulations. Review the [Microsoft Cloud for Sovereignty policy portfolio](https://github.com/Azure/cloud-for-sovereignty-policy-portfolio) for policies that support specific regulations, or follow the below steps to deploy your own policies alongside the SLZ.

## Customization step by step

The SLZ allows for custom policy initiatives to be deployed within the standard management group scopes for each deployment through the following:

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
3. Select the file for management group scope that you want custom policies to apply to and if you want to apply custom policies to all application workloads then select `slzLandingZoneCustom.json`
4. If custom policies have not been added yet, then the custom policy file will look like the screenshot below. Do NOT edit the `policyType`, `id`, `type`, or `name` fields. You will update the `parameters`, `policyDefinitions`, and `policyDefinitionGroups` as described by the [initiative definition structure](https://learn.microsoft.com/azure/governance/policy/concepts/initiative-definition-structure)
5. Grouping policies together on the [SLZ dashboard](./Extending-Compliance-Dashboard.md) is accomplished by adding `dashboard-` to the beginning of the policy definition group name, but any name can be used. The documentation for the [policy set definition group structure](https://learn.microsoft.com/azure/governance/policy/concepts/initiative-definition-structure#policy-definition-groups) describes the group structure further. A valid policy definition group can be found below:
```
    {
        "name": "dashboard-NIST_SP_800-171_R2",
        "category": "Regulatory Compliance",
        "description": "NIST 800-171 rev2"
    }
```     
6. Passing values to the custom policy definitions is not currently supported. You can set default values in the definition file or in the assignment file (located in the `/custom/policies/assignments` folder) but you cannot pass in values from the orchestration script at this time. Documentation on the assignment structure and how to set parameters is located [here](https://learn.microsoft.com/azure/governance/policy/concepts/assignment-structure)
7. Once you have added the custom policies to the policy set file, you only need to save the file and run `.\New-SovereignLandingZone.ps1` with either the `all`, or `compliance` deployment step and your custom policies will be added and assigned to the appropriate management group scopes.
8. If you need to change a policy effect, you will need to make that change to the above definitions and redeploy the SLZ as above. For documentation on how to set a policy effect please review the documentation [here](https://learn.microsoft.com/azure/governance/policy/concepts/effects)

**Note** Custom policies will need to fit with the [Azure policy and policy rule limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-policy-limits) otherwise Azure will not create the definitions.

## Next step

[View your compliance dashboard.](../10-Compliance-Dashboard.md)

### [Microsoft Legal Notice](../NOTICE.md)
