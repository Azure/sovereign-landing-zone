// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This is the main file for the deployment of the management group resources. It will deploy the following resources:
    - Management group resource groups
    - Management group managed identity
    - Management group role assignment
    - Management group logging
    - Management group hub networking
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('The prefix that will be added to all resources created by this deployment.')
@minLength(2)
@maxLength(5)
param parDeploymentPrefix string

@description('The suffix that will be added to management group suffix name the same way to be added to management group prefix names.')
@maxLength(5)
param parDeploymentSuffix string = ''

@description('Deployment location')
@allowed([
  'australiacentral'
  'australiacentral2'
  'australiaeast'
  'australiasoutheast'
  'brazilsouth'
  'brazilsoutheast'
  'brazilus'
  'canadacentral'
  'canadaeast'
  'centralindia'
  'centralus'
  'centraluseuap'
  'eastasia'
  'eastus'
  'eastus2'
  'eastus2euap'
  'eastusstg'
  'francecentral'
  'francesouth'
  'germanynorth'
  'germanywestcentral'
  'israelcentral'
  'italynorth'
  'japaneast'
  'japanwest'
  'jioindiacentral'
  'jioindiawest'
  'koreacentral'
  'koreasouth'
  'northcentralus'
  'northeurope'
  'norwayeast'
  'norwaywest'
  'polandcentral'
  'qatarcentral'
  'southafricanorth'
  'southafricawest'
  'southcentralus'
  'southcentralusstg'
  'southeastasia'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'switzerlandwest'
  'uaecentral'
  'uaenorth'
  'uksouth'
  'ukwest'
  'westcentralus'
  'westeurope'
  'westindia'
  'westus'
  'westus2'
  'westus3'
])
param parDeploymentLocation string

@description('Set how long logs are retained for, in days. DEFAULT: 365')
@minValue(30)
@maxValue(730)
param parLogRetentionInDays int = 365

@description('Subscription ID for management group.')
param parManagementSubscriptionId string

@description('Subscription ID for identity group.')
param parIdentitySubscriptionId string

@description('Subscription ID for connectivity group.')
param parConnectivitySubscriptionId string

@description('Testing variable, set to false to skip deploying the hub network resources. DEFAULT: true')
param parDeployHubNetwork bool = true

@description('Set to true to deploy Azure Bastion service, otherwise false. DEFAULT: true')
param parDeployBastion bool = true

@description('Set to true for DDoS protection, otherwise false. DEFAULT: true')
param parDeployDdosProtection bool = true

@description('Set to true for premium firewall, otherwise false. DEFAULT: true')
param parUsePremiumFirewall bool = true

@description('Tags to be added to deployed resources')
param parTags object = {}

@description('Hub network subnet. DEFAULT: 10.20.0.0/16')
param parHubNetworkAddressPrefix string = '10.20.0.0/16'

@description('The name and IP address range for each subnet in the virtual networks.')
param parSubnets array = [
  {
    name: 'AzureBastionSubnet'
    ipAddressRange: '10.20.15.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
  {
    name: 'GatewaySubnet'
    ipAddressRange: '10.20.252.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
  {
    name: 'AzureFirewallSubnet'
    ipAddressRange: '10.20.254.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
]

@description('The SKU for the Express Route Gateway. Default: standard')
param parExpressGatewaySku string = ''

@description('Express route gateway vpn type. Default:RouteBased')
param parExpressGatewayVpntype string = 'RouteBased'

@description('Express route gateway generation. Default:null')
param parExpressGatewayGeneration string = ''

@description('Express route border gateway protocol. Default: false')
param parExpressGatewayEnableBgp bool = false

@description('Create highly available active-active gateways. Default: false')
param parExpressGatewayActiveActive bool = false

@description('Gets or sets enable BGP routes translation for NAT on this gateway. Default:false')
param parExpressGatewayEnableBgpRouteTranslationForNat bool = false

@description('Configure DNS forwarding for gateway. Default: false')
param parExpressGatewayEnableDnsForwarding bool = false

@description('Express Gateway ASN. Default: 65515')
param parExpressGatewayAsn int = 65515

@description('Bgp peer address. Default:""')
param parExpressGatewayBgpPeeringAddress string = ''

@description('Bgp peer weight. Default:5')
param parExpressGatewayPeerWeight int = 5

@description('The SKU for the VPN Gateway. Default:VpnGw1')
param parVpnGatewaySku string = ''

@description('VPN type.  Default: RouteBased')
param parVpnGatewayVpntype string = 'RouteBased'

@description('VPN gateway generation. Default: Generation1')
param parVpnGatewayGeneration string = 'Generation1'

@description('VPN gateway border gateway protocol. Default: false')
param parVpnGatewayEnableBgp bool = false

@description('Create highly available active-active gateways. Default: false')
param parVpnGatewayActiveActive bool = false

@description('Gets or sets enable BGP routes translation for NAT on this gateway. Default: false')
param parVpnGatewayEnableBgpRouteTranslationForNat bool = false

@description('Configure DNS forwarding for gateway. Default: false')
param parVpnGatewayEnableDnsForwarding bool = false

@description('VPN gateway ASN. Default: 65515')
param parVpnGatewayAsn int = 65515

@description('Bgp peer address. Default: ""')
param parVpnGatewayBgpPeeringAddress string = ''

@description('Bgp peer weight. Default: 5')
param parVpnGatewayPeerWeight int = 5

@description('Vpn Client Configuration. Default: {}')
param parVpnGatewayClientConfiguration object = {}

@description('Enable Firewall. Default:True')
param parEnableFirewall bool = true

@description('Switch to enable/disable Azure Firewall Policies deployment.')
param parAzFirewallPoliciesEnabled bool = true

@sys.description('Optional List of Custom Public IPs, which are assigned to firewalls ipConfigurations.')
param parAzFirewallCustomPublicIps array = []

@description('Define outbound destination ports or ranges for SSH or RDP that you want to access from Azure Bastion.')
param parBastionOutboundSshRdpPorts array = [ '22', '3389' ]

@description('Testing variable, set to false to skip deploying the log analytics workspace. DEFAULT: true')
param parDeployLogAnalyticsWorkspace bool = true

var varManagementGroupId = '${parDeploymentPrefix}${parDeploymentSuffix}'

// Deploy management group resource groups
module modManagementResourceGroups '../../modules/resourceGroups/managementResourceGroups.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-Management-Resource-Groups${parDeploymentSuffix}', 64)
  scope: subscription(parManagementSubscriptionId)
  params: {
    parTags: parTags
    parDeploymentLocation: parDeploymentLocation
    parDeploymentPrefix: parDeploymentPrefix
    parDeploymentSuffix: parDeploymentSuffix
  }
}

// Deploy connectivity resource groups
module modConnectivityResourceGroups '../../modules/resourceGroups/connectivityResourceGroups.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-Connectivity-Resource-Groups${parDeploymentSuffix}', 64)
  scope: subscription(parConnectivitySubscriptionId)
  params: {
    parTags: parTags
    parDeploymentLocation: parDeploymentLocation
    parDeploymentPrefix: parDeploymentPrefix
    parDeploymentSuffix: parDeploymentSuffix
  }
}

// Deploy identity resource groups
module modIdentityResourceGroups '../../modules/resourceGroups/identityResourceGroups.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-Identity-Resource-Groups${parDeploymentSuffix}', 64)
  scope: subscription(parIdentitySubscriptionId)
  params: {
    parTags: parTags
    parDeploymentLocation: parDeploymentLocation
    parDeploymentPrefix: parDeploymentPrefix
    parDeploymentSuffix: parDeploymentSuffix
  }
}

// Deploy managed identity
module modManagedIdentity '../../modules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-Managed-Identity${parDeploymentSuffix}', 64)
  scope: resourceGroup(parIdentitySubscriptionId, '${parDeploymentPrefix}-rg-managed-identities-${parDeploymentLocation}${parDeploymentSuffix}')
  params: {
    parLocation: parDeploymentLocation
    parName: '${parDeploymentPrefix}-managed-identity-${parDeploymentLocation}${parDeploymentSuffix}'
    parTags: parTags
  }
  dependsOn: [
    modIdentityResourceGroups
  ]
}

//  Deploy role assignments
module modRoleAssignmentManagementGroup '../../dependencies/infra-as-code/bicep/modules/roleAssignments/roleAssignmentManagementGroup.bicep' = {
  name: take('${parDeploymentPrefix}-deploy-Role-Assignment-Management-Group${parDeploymentSuffix}', 64)
  scope: managementGroup(varManagementGroupId)
  params: {
    parAssigneeObjectId: modManagedIdentity.outputs.outPrincipalId
    parAssigneePrincipalType: 'ServicePrincipal'
    parRoleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    parTelemetryOptOut: true
  }
  dependsOn: [
    modIdentityResourceGroups
    modManagedIdentity
  ]
}

// Deploy logging resources
module modLogging '../../dependencies/infra-as-code/bicep/modules/logging/logging.bicep' = if (parDeployLogAnalyticsWorkspace) {
  name: take('${parDeploymentPrefix}-deploy-Logging${parDeploymentSuffix}', 64)
  scope: resourceGroup(parManagementSubscriptionId, '${parDeploymentPrefix}-rg-logging-${parDeploymentLocation}${parDeploymentSuffix}')
  params: {
    parAutomationAccountLocation: parDeploymentLocation
    parLogAnalyticsWorkspaceLocation: parDeploymentLocation
    parAutomationAccountName: '${parDeploymentPrefix}-automation-account-${parDeploymentLocation}${parDeploymentSuffix}'
    parLogAnalyticsWorkspaceLogRetentionInDays: parLogRetentionInDays
    parLogAnalyticsWorkspaceName: '${parDeploymentPrefix}-log-analytics-${parDeploymentLocation}${parDeploymentSuffix}'
    parLogAnalyticsWorkspaceSolutions: [
      'AgentHealthAssessment'
      'AntiMalware'
      'ChangeTracking'
      'Security'
      'SecurityInsights'
      'ServiceMap'
      'SQLAssessment'
      'Updates'
      'VMInsights'
    ]
    parTags: parTags
    parTelemetryOptOut: true
  }
  dependsOn: [
    modManagementResourceGroups
  ]
}

// Deploy hub networking resources
module modHubNetworking '../../dependencies/infra-as-code/bicep/modules/hubNetworking/hubNetworking.bicep' = if (parDeployHubNetwork) {
  name: take('${parDeploymentPrefix}-deploy-Hub-Network${parDeploymentSuffix}', 64)
  scope: resourceGroup(parConnectivitySubscriptionId, '${parDeploymentPrefix}-rg-hub-network-${parDeploymentLocation}${parDeploymentSuffix}')
  params: {
    parAzFirewallEnabled: parEnableFirewall
    parAzFirewallName: '${parDeploymentPrefix}-afw-${parDeploymentLocation}${parDeploymentSuffix}'
    parAzFirewallPoliciesEnabled: parAzFirewallPoliciesEnabled
    parAzFirewallTier: parUsePremiumFirewall ? 'Premium' : 'Standard'
    parAzBastionEnabled: parDeployBastion
    parAzBastionName: '${parDeploymentPrefix}-bas-${parDeploymentLocation}${parDeploymentSuffix}'
    parAzBastionSku: 'Standard'
    parCompanyPrefix: parDeploymentPrefix
    parDdosEnabled: parDeployDdosProtection
    parDdosPlanName: '${parDeploymentPrefix}-ddos-plan-${parDeploymentLocation}${parDeploymentSuffix}'
    parDisableBgpRoutePropagation: false
    parAzBastionNsgName: '${parDeploymentPrefix}-nsg-AzureBastionSubnet-${parDeploymentLocation}${parDeploymentSuffix}'
    parDnsServerIps: []
    parExpressRouteGatewayConfig: (empty(parExpressGatewaySku) || parExpressGatewaySku == null) ? {} : {
      name: '${parDeploymentPrefix}-erg-${parDeploymentLocation}${parDeploymentSuffix}'
      gatewaytype: 'ExpressRoute'
      sku: parExpressGatewaySku
      vpntype: parExpressGatewayVpntype
      vpnGatewayGeneration: parExpressGatewayGeneration
      enableBgp: parExpressGatewayEnableBgp
      activeActive: parExpressGatewayActiveActive
      enableBgpRouteTranslationForNat: parExpressGatewayEnableBgpRouteTranslationForNat
      enableDnsForwarding: parExpressGatewayEnableDnsForwarding
      asn: parExpressGatewayAsn
      bgpPeeringAddress: parExpressGatewayBgpPeeringAddress
      bgpsettings: {
        asn: parExpressGatewayAsn
        bgpPeeringAddress: parExpressGatewayBgpPeeringAddress
        peerWeight: parExpressGatewayPeerWeight
      }
    }
    parHubNetworkAddressPrefix: parHubNetworkAddressPrefix
    parHubNetworkName: '${parDeploymentPrefix}-hub-${parDeploymentLocation}${parDeploymentSuffix}'
    parHubRouteTableName: '${parDeploymentPrefix}-rt-${parDeploymentLocation}${parDeploymentSuffix}'
    parLocation: parDeploymentLocation
    parAzFirewallDnsProxyEnabled: true
    parPrivateDnsZones: [
      'privatelink.azure-automation.net'
      'privatelink${environment().suffixes.sqlServerHostname}'
      'privatelink.sql.azuresynapse.net'
      'privatelink.dev.azuresynapse.net'
      'privatelink.azuresynapse.net'
      'privatelink.blob.${environment().suffixes.storage}'
      'privatelink.table.${environment().suffixes.storage}'
      'privatelink.queue.${environment().suffixes.storage}'
      'privatelink.file.${environment().suffixes.storage}'
      'privatelink.web.${environment().suffixes.storage}'
      'privatelink.dfs.${environment().suffixes.storage}'
      'privatelink.documents.azure.com'
      'privatelink.mongo.cosmos.azure.com'
      'privatelink.cassandra.cosmos.azure.com'
      'privatelink.gremlin.cosmos.azure.com'
      'privatelink.table.cosmos.azure.com'
      'privatelink.${parDeploymentLocation}.batch.azure.com'
      'privatelink.postgres.database.azure.com'
      'privatelink.mysql.database.azure.com'
      'privatelink.mariadb.database.azure.com'
      'privatelink.vaultcore.azure.net'
      'privatelink.managedhsm.azure.net'
      'privatelink.${parDeploymentLocation}.azmk8s.io'
      'privatelink.${parDeploymentLocation}.backup.windowsazure.com'
      'privatelink.siterecovery.windowsazure.com'
      'privatelink.servicebus.windows.net'
      'privatelink.azure-devices.net'
      'privatelink.eventgrid.azure.net'
      'privatelink.azurewebsites.net'
      'privatelink.api.azureml.ms'
      'privatelink.notebooks.azure.net'
      'privatelink.service.signalr.net'
      'privatelink.monitor.azure.com'
      'privatelink.oms.opinsights.azure.com'
      'privatelink.ods.opinsights.azure.com'
      'privatelink.agentsvc.azure-automation.net'
      'privatelink.afs.azure.net'
      'privatelink.datafactory.azure.net'
      'privatelink.adf.azure.com'
      'privatelink.redis.cache.windows.net'
      'privatelink.redisenterprise.cache.azure.net'
      'privatelink.purview.azure.com'
      'privatelink.purviewstudio.azure.com'
      'privatelink.digitaltwins.azure.net'
      'privatelink.azconfig.io'
      'privatelink.cognitiveservices.azure.com'
      'privatelink${environment().suffixes.acrLoginServer}'
      'privatelink.search.windows.net'
      'privatelink.azurehdinsight.net'
      'privatelink.media.azure.net'
      'privatelink.his.arc.azure.com'
      'privatelink.guestconfiguration.azure.com'
    ]
    parPrivateDnsZonesEnabled: true
    parPrivateDnsZonesResourceGroup: '${parDeploymentPrefix}-rg-hub-network-${parDeploymentLocation}${parDeploymentSuffix}'
    parPublicIpSku: 'Standard'
    parPublicIpSuffix: '-PublicIP${parDeploymentSuffix}'
    parAzFirewallCustomPublicIps: parAzFirewallCustomPublicIps
    parSubnets: parSubnets
    parTags: parTags
    parTelemetryOptOut: true
    parBastionOutboundSshRdpPorts: parBastionOutboundSshRdpPorts
    parVpnGatewayConfig: (empty(parVpnGatewaySku) || parVpnGatewaySku == null) ? {} : {
      name: '${parDeploymentPrefix}-vpng-${parDeploymentLocation}${parDeploymentSuffix}'
      gatewaytype: 'Vpn'
      sku: parVpnGatewaySku
      vpntype: parVpnGatewayVpntype
      generation: parVpnGatewayGeneration
      enableBgp: parVpnGatewayEnableBgp
      activeActive: parVpnGatewayActiveActive
      enableBgpRouteTranslationForNat: parVpnGatewayEnableBgpRouteTranslationForNat
      enableDnsForwarding: parVpnGatewayEnableDnsForwarding
      asn: parVpnGatewayAsn
      bgpPeeringAddress: parVpnGatewayBgpPeeringAddress
      bgpsettings: {
        asn: parVpnGatewayAsn
        bgpPeeringAddress: parVpnGatewayBgpPeeringAddress
        peerWeight: parVpnGatewayPeerWeight
      }
      vpnClientConfiguration: parVpnGatewayClientConfiguration
    }
  }
  dependsOn: [
    modConnectivityResourceGroups
  ]
}

output outConnectivitySubscriptionId string = parConnectivitySubscriptionId
output outDeploymentLocation string = parDeploymentLocation
output outDeploymentPrefix string = parDeploymentPrefix
output outDdosProtectionResourceId string = parDeployHubNetwork && parDeployDdosProtection ? modHubNetworking.outputs.outDdosPlanResourceId : ''
output outLogAnalyticsWorkspaceId string = parDeployLogAnalyticsWorkspace ? modLogging.outputs.outLogAnalyticsWorkspaceId : ''
output outAutomationAccountName string = parDeployLogAnalyticsWorkspace ? modLogging.outputs.outAutomationAccountName : ''
output outPrivateDNSZones array = parDeployHubNetwork ? modHubNetworking.outputs.outPrivateDnsZones : []
output outHubVirtualNetworkId string = parDeployHubNetwork ? modHubNetworking.outputs.outHubVirtualNetworkId : ''
output outHubRouteTableId string = parDeployHubNetwork ? modHubNetworking.outputs.outHubRouteTableId : ''
output outHubRouteTableName string = parDeployHubNetwork ? modHubNetworking.outputs.outHubRouteTableName : ''
output outBastionNsgId string = parDeployHubNetwork ? modHubNetworking.outputs.outBastionNsgId : ''
output outBastionNsgName string = parDeployHubNetwork ? modHubNetworking.outputs.outBastionNsgName : ''
