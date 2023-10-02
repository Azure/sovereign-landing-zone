# Upgrading an existing Sovereign Landing Zone from Private Preview

**Note:** This document is intended for customers that have an existing SLZ Preview deployment from one of our Private Previews. If you are deploying the SLZ Preview for the first time or as part of the Public Preview, please go to [Deployment Parameters](07-Deployment-Parameters.md) to continue.

We are planning for all releases starting with Public Preview to have automatic upgrade steps that require no manual user interaction. However, please review each release note for more details. There are breaking changes introduced with Public Preview that prevent Private Preview upgrades.

## Parameter File Changes

Several parameters were changed, renamed, removed, or added. We recommend using the template parameter file provided in the Public Preview repository and updating the values there with the ones that were being used in your Private Preview deployment based upon the guidance below.

Any parameter that is not mentioned below can have its value copied over without modification.

### Parameters Changed or Removed

|    | Parameter Name | Status | Action | Notes |
|----|----------------|--------|--------|-------|
|  1 |parTopLevelManagementGroupSuffix|Renamed|Copy the value to the `parDeploymentSuffix` parameter.|This parameter is now called `parDeploymentSuffix` to better reflect its actual usage.|
|  2 |parBillingScopeAccountId|Combined|Record this parameter value and reference the new format in the [deployment parameter doc.](./07-Deployment-Parameters.md)|The parameter has been merged with `parEnrollmentAccountId` and is now called `parSubscriptionBillingScope` to allow for non-EA account types to deploy the SLZ Preview.|
|  3 |parEnrollmentAccountId|Combined|Record this parameter value and reference the new format in the [deployment parameter doc.](./07-Deployment-Parameters.md)|The parameter has been merged with `parBillingScopeAccountId` and is now called `parSubscriptionBillingScope` to allow for non-EA account types to deploy the SLZ Preview.|
|  4 |parEnvironmentType|Removed|None|This parameter has been removed as it is not being used.|

### Parameters Added

|    | Parameter Name | Status | Action | Notes |
|----|----------------|--------|--------|-------|
|  1 |parDeploymentSuffix|Renamed|Copy the value from `parTopLevelManagementGroupSuffix` parameter.|This parameter was called `parTopLevelManagementGroupSuffix` but it is used for more than the management group suffix.|
|  2 |parTopLevelManagementGroupParentId|Added|None, optional parameter.|This parameter enables SLZ Preview deployments outside the tenant root group level. [More details here.](./scenarios/Piloting-SLZ.md)|
|  3 |parSubscriptionBillingScope|Combined|Copy the `parBillingScopeAccountId` and `parEnrollmentAccountId` values into the new format.|This parameter is a combination of `parBillingScopeAccountId` and `parEnrollmentAccountId` to allow for non-EA account types to deploy the SLZ Preview. More details in the [deployment parameter doc.](./07-Deployment-Parameters.md)|
|  4 |parCustomSubnets|Added|None, optional parameter.|This parameter allows for more subnets to be added to the hub network. More details in the [deployment parameter doc.](./07-Deployment-Parameters.md)|
|  5 |parPolicyEffect|Added|None, optional parameter.|This parameter allows changing the [Sovereignty Policy Baseline](./scenarios/Sovereignty-Policy-Baseline.md) assignment effect. More details in the [deployment parameter doc.](./07-Deployment-Parameters.md)|
|  6 |parDeployLogAnalyticsWorkspace|Added|None, optional parameter.|This parameter toggles between deploying or not deploying Log Analytics Workspace. More details in the [deployment parameter doc.](./07-Deployment-Parameters.md)|
|  7 |parCustomerPolicySets|Added|None, optional parameter.|This parameter allows for assigning additional policies to the top-level management group scope. More details in the [deployment parameter doc.](./07-Deployment-Parameters.md)|
|  8 |parTags|Added|None, optional parameter.|This parameter allows for customizing resource tagging. More details in the [deployment parameter doc.](./07-Deployment-Parameters.md)|

## Naming Convention Changes

In an effort to align with ALZ naming conventions, several resources have been renamed. For the following table `prefix` will denote the value of `parDeploymentPrefix`, `suffix` will denote the value of `parDeploymentSuffix`, and `location` will denote the value of `parDeploymentLocation`.

**Note:** The `parDeploymentSuffix` value does not inherently provide a `-`. If a `-` is needed, it will need to be explicitly provided in the `parDeploymentSuffix` value.

|    | Resource Type | New Naming Format | Notes |
|----|---------------|-------------------|-------|
|  1 |Management Groups|No Change||
|  2 |Subscriptions|`{prefix}-[NAME]{suffix}`|Where `NAME` is the name of the subscription such as `connectivity`.|
|  3 |Resource Groups|`{prefix}-rg-[NAME]-{location}{suffix}`|Where `NAME` is the name of the resource group such as `hub-network`.|
|  4 |Resources|`{prefix}-[NAME]-{location}{suffix}`|Where `NAME` is the name of the resource such as `hub`.|||

Due to other Azure requirements around naming for Azure-managed resources or resource definitions that are internal to another resources, some Azure resources may not follow the above conventions.

## Breaking Changes

For the most part, Azure resources cannot be renamed as the name is used as the unique identifier for the resource. By using a standardize naming convention for resources deployed by the SLZ Preview, we have changed these names from the Private version of the SLZ Preview, so existing resources cannot be used by the Public version of the SLZ Preview.

To use the Public version of the SLZ Preview, we recommend the following:

1. Start with the new parameter file template found in this repository.
2. Copy the parameter values from the Private Preview parameter file to the Public Preview template.
   * Update the parameter values as described above.
3. Make sure you are using a `parDeploymentPrefix` and `parDeploymentSuffix` set that is not used by an existing Private Preview deployment.
4. Deploy the SLZ Preview as described in the [following step](08-Deploy-SLZ-Preview.md).
5. Run all post-deployment customizations you've made against this new SLZ Preview deployment.

## Next step

Proceed to [configure the parameters required for the SLZ Preview deployment](07-Deployment-Parameters.md)

### [Preview Notice](./PREVIEW.md)
