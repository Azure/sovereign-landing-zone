# Key Components of the Sovereign Landing Zone Deployment

## Components

The Sovereign Landing Zone consists of several components that are deployed as part of a full deployment. Each of the components are described below:

1. **Bootstrap**: Sets up the management group hierarchy and creates the subscriptions as dictated by the architecture of the SLZ. These are deployed under the tenant root group of the Azure customer tenant by default, although they can also be deployed under any [child management group](scenarios/Piloting-SLZ.md).

2. **Platform**: Sets up the hub network and logging resources used by the SLZ platform and workloads.

3. **Compliance**: Creates definitions and assigns the [default policy sets](scenarios/Sovereignty-Baseline-Policy-Initiatives.md) and provided custom policies to be enforced in the environment. For information on how to fully customize policies in the SLZ review our [customize policies](09-Customize-Policies.md) doc.

4. **Dashboard**: Provides customers with a visual representation of their Azure policy compliance. For additional information about the dashboard review our [compliance dashboard](10-Compliance-Dashboard.md) doc.

Once the deployment is complete, the customer will have the Sovereign Landing Zone setup for their use, with a base set of policies applied. Customers can then begin to migrate workloads and apply additional policies as necessary. For more information about how these deployment steps can be ran individually or how a deployment can be automated, checkout the [SLZ Pipeline Deployments](scenarios/Pipeline-Deployments.md) doc.

## Next step

[Getting started with the GitHub Repository](04-Repository-Setup.md)

### [Microsoft Legal Notice](./NOTICE.md)
