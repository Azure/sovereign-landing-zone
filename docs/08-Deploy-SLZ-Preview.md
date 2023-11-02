# Deploy the Sovereign Landing Zone Preview using the PowerShell script

**Prerequisite:** Please be sure to follow the steps in [Permissions and Tooling](05-Permissions-Tooling.md) to ensure latest tools are installed and the right permissions levels are available.

## Deployment Steps

1. Open PowerShell.
1. In your version of the GitHub repository, navigate to `/orchestration/scripts`.
1. Run the `New-SovereignLandingZone.ps1` deployment script.
      - *Note: Must be in the scripts folder to run successfully.*
1. Follow the prompts to complete your deployment.
     - *Note: Enter `all` for a new deployment or run as `.\New-SovereignLandingZone.ps1 -parDeployment all`.*
     - See the [pipeline deployment](scenarios/Pipeline-Deployments.md) doc for more information about alternate deployment methods and the `New-SovereignLandingZone.ps1` script parameters.
1. Confirm deployment completion by navigating to the Azure Portal Dashboard link provided in the output.

Please reference [Frequently Asked Questions](12-FAQ.md) for commons errors and resolutions, or reference [Deployment Scenarios](scenarios/README.md) for common operations.

## Next step

[Deploy Customize Policies](09-Customize-Policies.md)

### [Preview Notice](./PREVIEW.md)
