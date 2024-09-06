# Workload Landing Zones

After the SLZ has been deployed, organizations can begin using it to host workloads. Workloads will need their own landing zones, and for more details about the types of landing zones review the [what is a landing zone](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/#platform-landing-zones-vs-application-landing-zones) documentation.

In short, the landing zone as deployed by the SLZ provides the governance framework and controls that can simplify the onboarding of workload landing zones within its management group structure. This means workload landing zones don't need to recreate common infrastructure such as a hub network as they may use the one that already exists, nor do they need to manage policy assignments as they'll inherent the ones already assigned.

Workload landing zones require the creation of a subscription and placing it within the management group structure. While you may [customize the management groups](Expanding-SLZ-ManagementGroups.md) available, the following exist by default:

1. [Connectivity](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/connectivity-to-azure) - Used to host platform workloads that provide core networking capabilities
2. [Identity](https://learn.microsoft.com/azure/cloud-adoption-framework/decision-guides/identity/) - Used to host platform workloads that provide identity management, access, and syncing capabilities
3. [Management](https://learn.microsoft.com/azure/cloud-adoption-framework/manage/monitor/) - Used to host platform workloads that provide core monitoring and alerting capabilities
4. Corp - Used to host application workloads that do not need to be accessed from the public internet
5. Confidential Corp - Used to host application workloads that do not need to be accessed from the public internet but require use of confidential computing
6. Online - Used to host application workloads that do need to be accessed from the public internet
7. Confidential Online - Used to host application workloads that do need to be accessed from the public internet but require use of confidential computing
8. [Sandbox](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/sandbox-environments) - Used to host isolated environments for testing workloads and capabilities
9. [Decommissioned](https://learn.microsoft.com/azure/cloud-adoption-framework/migrate/migration-considerations/optimize/decommission) - Used to host workloads or capabilities that are retired, but still need to be retained

# Landing Zone Vending

[Subscription vending](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending) provides a platform mechanism for programmatically issuing subscriptions to application teams that need to deploy workloads. This notion allows for an organization's governance and security teams to build controls and a process around subscription creation, then application teams can request a new subscription for their workload on demand after making a few choices.

[Landing zone vending](https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/lz/sub-vending) is a GitHub repository that provides the automation to deploy landing zones for workloads within the SLZ. It is recommended for an organization's governance and security teams to review the parameters available in this module and enforce certain values for some, while leaving the others up to the requesting team to fill out. Once all values are added, then a pipeline running with a highly privileged account would create the landing zone and grant reduced permissions to the development team to deploy their workload within.

It is recommended to not allow a development team set the following values:

* deploymentScript*
* hubNetworkResourceId
* resourceProviders
* roleAssignmentEnabled
* roleAssignments
* subscriptionAliasEnabled
* subscriptionBillingScope
* subscriptionManagementGroupAssociationEnabled
* subscriptionTenantId
* virtualNetwork*

It is recommended to allow a development team to set the following values (with custom business logic as is needed):

* subscriptionDisplayName
* subscriptionAliasName
* subscriptionWorkload
* subscriptionManagementGroupId
* subscriptionTags

However, organizations may customize these lists further and provide certain allowed values that a development team can request.

# SLZ Logging

To support usage of the landing zone vending module and [running individual deployment steps](Pipeline-Deployments.md), during every execution of the SLZ key resources will be logged to a CSV file. These log files will be stored in `/orchestration/scripts/outputs` and will be timestamped with the deployment name in the title.

The CSV file has the following columns:
* Resource Name - The human readable resource name
* Resource Type - The resource type useful for filtering the CSV
* Resource Id - The unique identifier for the resource that's commonly needed as a parameter
* Deployment Module - The deployment module where this resource is created
* Comments - A human readable comment about where this value is commonly used

# Workload Templates

Microsoft Cloud for Sovereignty has published a variety of [workload templates](https://github.com/Azure/cloud-for-sovereignty-quickstarts) including a sample application that are designed to be deployed within the SLZ. These are useful resources to reference during the workload migration process.

### [Microsoft Legal Notice](../NOTICE.md)
