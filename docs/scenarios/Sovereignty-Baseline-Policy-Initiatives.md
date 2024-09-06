# Sovereignty Baseline Policy Initiatives

The Sovereignty Baseline policy initiatives (baseline) is one of the sets of policy initiatives in the [Microsoft Cloud for Sovereignty policy portfolio](https://learn.microsoft.com/industry/sovereignty/policy-portfolio-baseline). It comes deployed within every SLZ environment and can be [used outside an SLZ](https://github.com/Azure/cloud-for-sovereignty-policy-portfolio/) environment.

The baseline is intended to supplement existing security control frameworks used by customers today with Azure policies that are grouped into the sovereignty control objectives listed below. It is not intended to replace a security control framework or fully meet the sovereignty control objectives by themselves. It should be viewed as providing a starting point for best practices past what traditional control frameworks may require and supports an organization's effort in addressing the listed control objectives.

The baseline does this by introducing the notion of **customer-defined sensitive** data, which is not meant to map to any data classification framework. Instead it is there to differentiate data that an organization denotes as having additional sovereignty requirements. The below sovereignty control objectives are examples of the types of controls that an organization may have for protecting **customer-defined sensitive** data. The related policies to these objectives are only assigned to the confidential scopes while other controls are applied to all resources.

## Configuring the Baseline

The following parameters are useful for configuring the policy baseline:

1. `parAllowedLocations` - This is applied to all resources to restrict the regions where they can be deployed.
2. `parAllowedLocationsForConfidentialComputing` - This is applied to all resources within the confidential scopes to restrict the regions where they can be deployed. Resources under this scope are exempt from the `parAllowedLocations` rule to support cases where confidential computing is not currently available in the desired region.
3. `parPolicyEffect` - This is the policy effect used by all policies within the baseline that supports the effect.

## Sovereignty Control Objectives

### SO-1

**Customer data must be stored and processed entirely in data centers that reside in approved geopolitical regions based upon customer-defined requirements.**

The related policies are in the `SO.1 - Data Residency` group within these files:

* [SLZ Global Defaults](https://learn.microsoft.com/azure/governance/policy/samples/mcfs-baseline-global#so1---data-residency)
* [SLZ Confidential Defaults](https://learn.microsoft.com/azure/governance/policy/samples/mcfs-baseline-confidential#so1---data-residency)

### SO-2

**Customers must approve the access of customer data by cloud and managed service operators.**

There is no policy in the baseline that supports this and it is intended to be addressed by enabling [Customer Lockbox](https://learn.microsoft.com/azure/security/fundamentals/customer-lockbox-overview).

### SO-3

**Customer-defined sensitive customer data must only be accessible in an encrypted manner to cloud and managed service operators.**

The related policies are in the `SO.3 - Customer-Managed Keys` group within these files:

* [SLZ Confidential Defaults](https://learn.microsoft.com/azure/governance/policy/samples/mcfs-baseline-confidential#so3---customer-managed-keys)

**Note** The resources are intended to be restricted to only those that have SKUs backed by confidential computing or do not process customer data. If this list is too restrictive, users are recommended to add other approved resources to the [allowed resources list](../../dependencies/infra-as-code/bicep/modules/policy/assignments/lib/policy_assignments/policy_assignment_es_enforce_sovereignty_baseline_conf.tmpl.json) in the assignment definition.

### SO-4

**The customer must have exclusive control over deciding which identities can access keys used to decrypt customer-defined sensitive data.**

The related policies are in the `SO.4 - Azure Confidential Computing` group within these files:

* [SLZ Confidential Defaults](https://learn.microsoft.com/azure/governance/policy/samples/mcfs-baseline-confidential#so4---azure-confidential-computing)

### SO-5

**The customer must have assurance that the supply chain for VM disk images has not been altered.**

The related policies are in the `SO.5 - Trusted Launch` group within these files:

* [SLZ Global Defaults](https://learn.microsoft.com/azure/governance/policy/samples/mcfs-baseline-global#so5---trusted-launch)

## Improvement Ideas

The Sovereignty Baseline policy initiatives are exploring a new space and we are eager to hear any suggestions about how they should be structured, other control objectives that should be included, how they should support specific workload architectures, or any other areas. Please submit any [feedback or improvement ideas](https://github.com/Azure/sovereign-landing-zone/issues/new/choose) you may have.

### [Microsoft Legal Notice](../NOTICE.md)
