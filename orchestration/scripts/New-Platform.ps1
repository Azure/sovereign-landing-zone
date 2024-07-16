# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
    The powershell script deploys platform as part of SLZ deployment.
#>
param (
    $parAttendedLogin = $true
)
. ".\Invoke-Helper.ps1"

#variables
$varSovereignPlatformBicepFilePath = '..\sovereignPlatform\sovereignPlatform.bicep'
$varPlatformRequiredParams = @('parDeploymentPrefix', 'parDeploymentLocation', 'parManagementSubscriptionId', 'parIdentitySubscriptionId', 'parConnectivitySubscriptionId')
<#
.Description
    Deploys resources and resource groups to subscriptions
    Parameters:
    parPlatformParametersFilePath -> path to the parameter file containing required parameters to deploy platform
    varParameters -> hash table containing parameter name and value
    modDeployBootstrapOutputs -> hash table containing parameter outputs from bootstrap deployment
#>
function New-Platform {
    param($parPlatformParametersFilePath, $parParameters, $parDeployBootstrapOutputs)

    if (!$parParameters -and !$parDeployBootstrapOutputs) {
        $parParameters = Read-ParametersValue($parPlatformParametersFilePath)
        Confirm-Parameters($varPlatformRequiredParams)
        Get-DonotRetryErrorCodes
    }

    if ($parDeployBootstrapOutputs) {
        $varConnectivitySubscriptionId = $parDeployBootstrapOutputs.outputs.outConnectivitySubscriptionId.value
        $varIdentitySubscriptionId = $parDeployBootstrapOutputs.outputs.outIdentitySubscriptionId.value
        $varManagementSubscriptionId = $parDeployBootstrapOutputs.outputs.outManagementSubscriptionId.value
    }
    else {
        $varConnectivitySubscriptionId = $parParameters.parConnectivitySubscriptionId.value
        $varIdentitySubscriptionId = $parParameters.parIdentitySubscriptionId.value
        $varManagementSubscriptionId = $parParameters.parManagementSubscriptionId.value
    }
    if ([string]::IsNullOrEmpty($varConnectivitySubscriptionId) -or [string]::IsNullOrEmpty($varIdentitySubscriptionId) -or [string]::IsNullOrEmpty($varManagementSubscriptionId)) {
        Write-Error "One or more subscription id is missing. Please rerun the deployment." -ErrorAction stop
    }

    $modCheckSubscriptionsExistsOutput = Confirm-SubscriptionsExists $varConnectivitySubscriptionId $varManagementSubscriptionId $varIdentitySubscriptionId
    if ($modCheckSubscriptionsExistsOutput) {
        Write-Information ">>>Subscriptions found" -InformationAction Continue
    }
    else {
        Write-Error "One or more subscription not found. Please rerun the deployment." -ErrorAction stop
    }

    $parDeploymentPrefix = $parParameters.parDeploymentPrefix.value
    $parDeploymentSuffix = $parParameters.parDeploymentSuffix.value
    $varManagementGroupId = "$parDeploymentPrefix$parDeploymentSuffix"
    $parDeploymentLocation = $parParameters.parDeploymentLocation.value
    $parDeployBastion = $parParameters.parDeployBastion.value

    $varSubnets = @(
        @{
            name                   = "AzureBastionSubnet"
            ipAddressRange         = $parParameters.parAzureBastionSubnet.value
            networkSecurityGroupId = ""
            routeTableId           = ""
        },
        @{
            name                   = "GatewaySubnet"
            ipAddressRange         = $parParameters.parGatewaySubnet.value
            networkSecurityGroupId = ""
            routeTableId           = ""
        },
        @{
            name                   = "AzureFirewallSubnet"
            ipAddressRange         = $parParameters.parAzureFirewallSubnet.value
            networkSecurityGroupId = ""
            routeTableId           = ""
        }
    )

    $varCustomSubnets = Convert-ToArray($parParameters.parCustomSubnets.value)
    foreach ($subnet in $varCustomSubnets) {
        if ($varSubnets.name.Contains($subnet.name)) {
            for ($i = 0; $i -lt $varSubnets.Length; $i++) {
                if ($varSubnets[$i]["name"] -ne $subnet.name) { continue }
                $varSubnets[$i]["ipAddressRange"] = $subnet.ipAddressRange
                $varSubnets[$i]["networkSecurityGroupId"] = $subnet.networkSecurityGroupId
                $varSubnets[$i]["routeTableId"] = $subnet.routeTableId
            }
        }
        else {

            $varSubnet = @{
                name                   = $subnet.name
                ipAddressRange         = $subnet.ipAddressRange
                networkSecurityGroupId = $subnet.networkSecurityGroupId
                routeTableId           = $subnet.routeTableId
            }

            $varSubnets += $varSubnet
        }
    }

    Confirm-BastionRequiredValue $parDeployBastion $varSubnets
    $deploymentName = "deploy-platform-$vartimeStamp"
    $varParams = @{
        parConnectivitySubscriptionId                    = $varConnectivitySubscriptionId
        parIdentitySubscriptionId                        = $varIdentitySubscriptionId
        parManagementSubscriptionId                      = $varManagementSubscriptionId
        parDeploymentPrefix                              = $parParameters.parDeploymentPrefix.value
        parDeploymentSuffix                              = $parParameters.parDeploymentSuffix.value
        parDeployDdosProtection                          = $parParameters.parDeployDdosProtection.value
        parDeployHubNetwork                              = $parParameters.parDeployHubNetwork.value
        parUsePremiumFirewall                            = $parParameters.parUsePremiumFirewall.value
        parEnableFirewall                                = $parParameters.parEnableFirewall.value
        parAzFirewallPoliciesEnabled                     = $parParameters.parAzFirewallPoliciesEnabled.value
        parAzFirewallCustomPublicIps                     = $parParameters.parAzFirewallCustomPublicIps.value
        parLogRetentionInDays                            = $parParameters.parLogRetentionInDays.value
        parDeploymentLocation                            = $parParameters.parDeploymentLocation.value
        parHubNetworkAddressPrefix                       = $parParameters.parHubNetworkAddressPrefix.value
        parDeployBastion                                 = $parParameters.parDeployBastion.value
        parSubnets                                       = $varSubnets
        parExpressGatewaySku                             = $parParameters.parExpressRouteGatewayConfig.value.sku
        parExpressGatewayVpntype                         = $parParameters.parExpressRouteGatewayConfig.value.vpntype
        parExpressGatewayGeneration                      = $parParameters.parExpressRouteGatewayConfig.value.vpnGatewayGeneration
        parExpressGatewayEnableBgp                       = $parParameters.parExpressRouteGatewayConfig.value.enableBgp
        parExpressGatewayActiveActive                    = $parParameters.parExpressRouteGatewayConfig.value.activeActive
        parExpressGatewayEnableBgpRouteTranslationForNat = $parParameters.parExpressRouteGatewayConfig.value.enableBgpRouteTranslationForNat
        parExpressGatewayEnableDnsForwarding             = $parParameters.parExpressRouteGatewayConfig.value.enableDnsForwarding
        parExpressGatewayAsn                             = [string]::IsNullOrEmpty($parParameters.parExpressRouteGatewayConfig.value.asn) ? 65515 : $parParameters.parExpressRouteGatewayConfig.value.asn
        parExpressGatewayBgpPeeringAddress               = $parParameters.parExpressRouteGatewayConfig.value.bgpPeeringAddress
        parExpressGatewayPeerWeight                      = [string]::IsNullOrEmpty($parParameters.parExpressRouteGatewayConfig.value.peerWeight) ? 5 : $parParameters.parExpressRouteGatewayConfig.value.peerWeight
        parVpnGatewaySku                                 = $parParameters.parVpnGatewayConfig.value.sku
        parVpnGatewayVpntype                             = $parParameters.parVpnGatewayConfig.value.vpntype
        parVpnGatewayGeneration                          = $parParameters.parVpnGatewayConfig.value.generation
        parVpnGatewayEnableBgp                           = $parParameters.parVpnGatewayConfig.value.enableBgp
        parVpnGatewayActiveActive                        = $parParameters.parVpnGatewayConfig.value.activeActive
        parVpnGatewayEnableBgpRouteTranslationForNat     = $parParameters.parVpnGatewayConfig.value.enableBgpRouteTranslationForNat
        parVpnGatewayEnableDnsForwarding                 = $parParameters.parVpnGatewayConfig.value.enableDnsForwarding
        parVpnGatewayAsn                                 = [string]::IsNullOrEmpty($parParameters.parVpnGatewayConfig.value.asn) ? 65515 : $parParameters.parVpnGatewayConfig.value.asn
        parVpnGatewayBgpPeeringAddress                   = $parParameters.parVpnGatewayConfig.value.bgpPeeringAddress
        parVpnGatewayPeerWeight                          = [string]::IsNullOrEmpty($parParameters.parVpnGatewayConfig.value.peerWeight) ? 5 : $parParameters.parVpnGatewayConfig.value.peerWeight
        parVpnGatewayClientConfiguration                 = $parParameters.parVpnGatewayConfig.value.vpnClientConfiguration
        parBastionOutboundSshRdpPorts                    = $parParameters.parBastionOutboundSshRdpPorts.value
        parDeployLogAnalyticsWorkspace                   = $parParameters.parDeployLogAnalyticsWorkspace.value
        parTags                                          = Convert-ToHashTable($parParameters.parTags.value)
    }
    $varLoopCounter = 0;
    $varRetry = $true
    while ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        $modDeploySovereignPlatform = $null
        try {
            Write-Information ">>> Platform deployment started" -InformationAction Continue

            $modDeploySovereignPlatform = New-AzManagementGroupDeployment `
                -Name $deploymentName `
                -Location $parDeploymentLocation `
                -TemplateFile $varSovereignPlatformBicepFilePath `
                -ManagementGroupId $varManagementGroupId `
                -TemplateParameterObject $varParams `
                -WarningAction Ignore

            if (!$modDeploySovereignPlatform) {
                $varRetry = $false
                Write-Error "Error while executing platform deployment script" -ErrorAction Stop
            }

            if ($modDeploySovereignPlatform.ProvisioningState -eq "Failed") {
                Write-Error "`n Error while executing platform deployment" -ErrorAction Stop
            }

            Write-Information ">>> Platform deployment completed`n" -InformationAction Continue
            # update parameters
            Out-DeploymentParameters "platform" $modDeploySovereignPlatform $varManagementGroupId $parParameters
            return $modDeploySovereignPlatform
        }
        catch {
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            if (!$varRetry) {
                Write-Error ">>> Validation error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            if (!$modDeploySovereignPlatform) {
                Write-Error ">>> Error occurred during execution . Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
            else {
                $varDeploymentErrorCodes = Get-FailedDeploymentErrorCodes $varManagementGroupId $deploymentName $varManagementGroupDeployment
                if ($null -eq $varDeploymentErrorCodes) {
                    $varRetry = $false
                }
                else {
                    $varLoopCounter++
                    $varRetry = Confirm-Retry $varDeploymentErrorCodes
                    if ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
                        Write-Information ">>> Retrying deployment after waiting for $varRetryWaitTimeTransientErrorRetry secs" -InformationAction Continue
                        Start-Sleep -Seconds $varRetryWaitTimeTransientErrorRetry
                    }
                    else {
                        $varRetry = $false
                        Write-Error ">>> Error occurred in platform deployment. Please try after addressing the above error." -ErrorAction Stop
                    }
                }
            }
        }
    }
}
