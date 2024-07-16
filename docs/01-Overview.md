# Understanding the Sovereign Landing Zone (SLZ)

## The Sovereign Landing Zone (SLZ)

The [Sovereign Landing Zone](https://learn.microsoft.com/industry/sovereignty/slz-overview) is a [Microsoft Cloud for Sovereignty](https://microsoft.com/sovereignty) offering that is an opinionated variant of the [Azure Landing Zone](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/), which provides an enterprise scale cloud infrastructure designed to help an organization meet their sovereignty requirements such as those related to operational control of data at rest, in transit, and in use.

With the SLZ a customer can create a cloud architecture that provides controls for [service location](https://azure.microsoft.com/explore/global-infrastructure/data-residency/) management, [customer managed keys](https://learn.microsoft.com/azure/security/fundamentals/key-management) and [confidential computing](https://learn.microsoft.com/azure/confidential-computing/overview-azure-products) as core components of the architecture. This enterprise scale cloud architecture bundled with policies and compliance reporting enables customers to create a platform for the secure and sovereign deployment of their workloads.

## Differences between the Sovereign Landing Zone and an Azure Landing Zone

The SLZ comes with the [Sovereignty Baseline policy initiatives](scenarios/Sovereignty-Baseline-Policy-Initiatives.md) built-in and enables other policy sets such as the [ALZ Policies](https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Policies) to be deployed within the SLZ and policy sets that support control frameworks such as [NIST 800-171 rev2](https://learn.microsoft.com/azure/governance/policy/samples/nist-sp-800-171-r2) and [Microsoft Cloud Security Benchmark](https://learn.microsoft.com/security/benchmark/azure/overview) to be layered on top of the SLZ. With the Sovereignty Baseline policy initiatives a customer can enforce the use of confidential computing and key management resources for appropriately implemented workloads to be deployed into confidential management groups allowing workload data to be protected at rest, in transit, and while in use thereby supporting an organization in achieving their data sovereignty goals.

The SLZ provides this through custom orchestration permitting an entire landing zone to be configured from a singular parameter file and deployed with a single command allowing organizations to quickly test out the SLZ.

## Benefits of using Sovereign Landing Zone (SLZ)

Securing government workloads in a public cloud is challenging. The SLZ automates the creation of a cloud environment where security and data sovereignty controls can be enforced by policies. The entire deployment is automated so that it can be integrated into existing pipelines as part of a mature DevSecOps ecosystem. 

## Conclusion

If you need the scale and flexibility of the public cloud combined with the peace of mind of knowing that data is encrypted at rest, in transit, and while in use, then you can benefit from the SLZ. View our [common scenarios](scenarios/README.md) for more details about how to use the SLZ or follow the next steps to get started.

## Next step

[Architecture of the Sovereign Landing Zone.](02-Architecture.md)

### [Microsoft Legal Notice](./NOTICE.md)
