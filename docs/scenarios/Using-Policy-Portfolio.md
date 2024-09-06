# Using the Policy Portfolio

The Microsoft Cloud for Sovereignty has as [policy portfolio](https://github.com/Azure/cloud-for-sovereignty-policy-portfolio) with each set of initiatives within the portfolio designed to help an organization demonstrate compliance against a country/region or industry specific regulation. Our [public documentation](https://learn.microsoft.com/industry/sovereignty/policy-portfolio-baseline) contains more information.

All sets of initiatives within the policy portfolio can be used in any landing zone, but have also been tested against workloads running within the SLZ. For the [sets of policies](https://github.com/Azure/cloud-for-sovereignty-policy-portfolio) that are not yet built-in, their definitions will need to be deployed in the top-level or parent management group for the SLZ prior to being deployed. Follow the documentation within the portfolio repository for more details. All others will be built-in and no additional setup steps are required.

To use one or more policy sets from the policy portfolio update the `parCustomerPolicySets` parameter with the assignment information. These assignments will be created at the specified management group scope, and with the optional parameters provided in the  `policyParameterFilePath` field within the `parCustomerPolicySets` parameter. See [Custom Policies](./Custom-Policies.md#Assigning-existing-initiatives) for more details.

### [Microsoft Legal Notice](../NOTICE.md)
