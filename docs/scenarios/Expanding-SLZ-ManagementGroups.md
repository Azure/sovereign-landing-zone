# Adding New Management Group Scopes to the SLZ

The SLZ deploys a standard set of management groups that are used to organize resources and manage policy assignments. This set also has the following recommended usage patterns:

1. [Connectivity](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/connectivity-to-azure) - Used to host platform workloads that provide core networking capabilities
2. [Identity](https://learn.microsoft.com/azure/cloud-adoption-framework/decision-guides/identity/) - Used to host platform workloads that provide identity management, access, and syncing capabilities
3. [Management](https://learn.microsoft.com/azure/cloud-adoption-framework/manage/monitor/) - Used to host platform workloads that provide core monitoring and alerting capabilities
4. Corp - Used to host application workloads that do not need to be accessed from the public internet
   * Public internet access restriction is provided by enabling the ALZ Policies
5. Confidential Corp - Used to host application workloads that do not need to be accessed from the public internet but require use of confidential computing
   * Public internet access restriction is provided by enabling the ALZ Policies
6. Online - Used to host application workloads that do need to be accessed from the public internet
7. Confidential Online - Used to host application workloads that do need to be accessed from the public internet but require use of confidential computing
8. [Sandbox](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/considerations/sandbox-environments) - Used to host isolated environments for testing workloads and capabilities
9. [Decommissioned](https://learn.microsoft.com/azure/cloud-adoption-framework/migrate/migration-considerations/optimize/decommission) - Used to host workloads or capabilities that are retired, but still need to be retained

The policy assignments will provide guardrails designed to support these usage patterns with the [Sovereignty Baseline policy initiatives](./Sovereignty-Baseline-Policy-Initiatives.md) enforcing confidential computing SKUs and if enabled the [ALZ policies](https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Policies) focus on security best practices.

As organizations use the SLZ they may find it useful refine their management group structure to group workloads further or under different contexts. This can be achieved by using the `parLandingZoneMgChildren` parameter value to create more sibling management groups to the Corp, Online, and Confidential variants. 

Note that custom management groups will need to manage policy assignments to them as post-deployment steps. Further developments will improve upon this customization experience.

### [Microsoft Legal Notice](../NOTICE.md)
