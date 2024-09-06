# Upgrading to Newer Versions of the SLZ

The following technical workflow describes the recommended process to upgrade to the newest version of the SLZ. Note that it is still the user's responsibility to validate that the upgrade was successful, that your workloads remain functional, and that your compliance posture is maintained.

1. Backup your copy of the [parameter file](../../orchestration/scripts/parameters/sovereignLandingZone.parameters.json) as git operations may result in merge conflicts.
2. Run a git pull from the `main` branch or checkout from the specific [release tag](https://github.com/Azure/sovereign-landing-zone/releases).
3. Follow the upgrade notes found in the release notes for the specific [release tag](https://github.com/Azure/sovereign-landing-zone/releases) being upgraded to.
    * All upgrade notes can be found [here](README.md).
4. Restore your [parameter file](../../orchestration/scripts/parameters/sovereignLandingZone.parameters.json) following any parameter changes described in the upgrade notes.
    * (Optional) Review any new parameters or capabilities to determine if these would offer value to your deployment.
5. Run the SLZ deployment script to apply the changes.
    * If you have a dev or test deployment of the SLZ, it is recommended to upgrade that deployment first.
    * Unless otherwise stated in the upgrade notes, all upgrades are expected to be successful with `.\New-SovereignLandingZone.ps1 -parDeployment all`
6. Validate the deployment with any custom validation steps you may have.

We intend for SLZ upgrades to be a relatively straightforward process with any net-new capabilities requiring explicit modifications to be made to the parameter file to enable.

However, it is worth noting that if post-deployment modifications to the SLZ were done without these changes being reflected in the parameter file, the SLZ upgrade process could revert these changes. This only happens for resources that the SLZ originally deployed or where the SLZ originally deployed the parent resource. For instance, post-deployment modifications creating new subnets in the hub VNET could be removed unless they are reflected in the `parCustomSubnets` parameter as the SLZ originally deployed the hub VNET.

For cases where you no longer need the SLZ orchestration to manage these resources, review our [using existing resources](../scenarios/Using-Existing-Resources.md) docs for further details.

### [Microsoft Legal Notice](../NOTICE.md)
