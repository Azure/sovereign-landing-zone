// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY : This template deploys a dashboard with all the compliance tiles for the SLZ
  AUTHOR/S: Cloud for Sovereignty
*/
@description('The name of the Dashboard')
param parDashboardName string

@description('The deployment location.')
param parLocation string

@description('The name of the country or agency SLZ is being deployed for. DEFAULT: Country')
param parCountryOrAgencyName string

@description('The prefix that will be added to all resources created by this deployment. E.g. mcfs')
@minLength(2)
@maxLength(5)
param parDeploymentPrefix string

@description('Tags to be added to deployed resources')
param parTags object

// Header
var varMarkdownHeaderText = loadTextContent('./templates/markdownPart.md')

// Load Query from Text Files
var varResourceComplianceScoreText = loadTextContent('./templates/resourceComplianceScore.csl')
var varResourcesbyComplianceStateText = loadTextContent('./templates/resourcesbyComplianceState.csl')
var varCompliancebySubscriptionText = loadTextContent('./templates/compliancebySubscription.csl')
var varCompliancebyPolicyInitiativeText = loadTextContent('./templates/compliancebyPolicyInitiative.csl')
var varListofNonCompliantResourcesText = loadTextContent('./templates/listofNonCompliantResources.csl')
var varResourcesOutsideofSafeRegionText = loadTextContent('./templates/resourcesOutsideofSafeRegion.csl')
var varListofResourcesExemptofDataResidentPolicyText = loadTextContent('./templates/listofResourcesExemptofDataResidentPolicy.csl')
var varListofResourcesOutsideofSafeRegionText = loadTextContent('./templates/listofResourcesOutsideofSafeRegion.csl')
var varConfidentialityScoreText = loadTextContent('./templates/confidentialityScore.csl')
var varDataResidencyScoreText = loadTextContent('./templates/dataResidencyScore.csl')
var varListOfResourcesExemptOfConfidentialPoliciesText = loadTextContent('./templates/listOfResourcesExemptOfConfidentialPolicies.csl')
var varComplianceByPolicyGroupText = loadTextContent('./templates/complianceByPolicyGroup.csl')
var varComplianceScoreForStoragePolicyGroupText = loadTextContent('./templates/complianceScoreForStoragePolicyGroup.csl')
var varComplianceScoreForTransportPolicyGroupText = loadTextContent('./templates/complianceScoreForTransportPolicyGroup.csl')
var varComplianceScoreForConfidentialComputingPolicyGroupText = loadTextContent('./templates/complianceScoreForConfidentialComputingPolicyGroup.csl')

// Queries
var varResourceComplianceScoreQuery = replace(varResourceComplianceScoreText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varResourcesbyComplianceStateQuery = replace(varResourcesbyComplianceStateText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varCompliancebyPolicyInitiativeQuery = replace(varCompliancebyPolicyInitiativeText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varCompliancebySubscriptionQuery = replace(varCompliancebySubscriptionText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varListofNonCompliantResourcesQuery = replace(varListofNonCompliantResourcesText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varResourcesOutsideofSafeRegionQuery = replace(varResourcesOutsideofSafeRegionText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varListofResourcesExemptofDataResidentPolicyQuery = replace(varListofResourcesExemptofDataResidentPolicyText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varListofResourcesOutsideofSafeRegionQuery = replace(varListofResourcesOutsideofSafeRegionText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varConfidentialityScoreQuery = replace(varConfidentialityScoreText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varDataResidencyScoreQuery = replace(varDataResidencyScoreText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varListOfResourcesExemptOfConfidentialPoliciesQuery = replace(varListOfResourcesExemptOfConfidentialPoliciesText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varComplianceByPolicyGroupQuery = replace(varComplianceByPolicyGroupText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varComplianceScoreForStoragePolicyGroupQuery = replace(varComplianceScoreForStoragePolicyGroupText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varComplianceScoreForTransportPolicyGroupQuery = replace(varComplianceScoreForTransportPolicyGroupText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)
var varComplianceScoreForConfidentialComputingPolicyGroupQuery = replace(varComplianceScoreForConfidentialComputingPolicyGroupText, 'RootPrefix_PLACEHOLDER', parDeploymentPrefix)

var varDefaultTitles = [
  {
    position: {
      x: 0
      y: 0
      colSpan: 8
      rowSpan: 2
    }
    metadata: {
      inputs: []
      type: 'Extension/HubsExtension/PartType/MarkdownPart'
      settings: {
        content: {
          settings: {
            content: varMarkdownHeaderText
            title: 'Sovereign landing zone dashboard for ${parDeploymentPrefix}'
            subtitle: parCountryOrAgencyName
            markdownSource: 1
            markdownUri: null
          }
        }
      }
      partHeader: {}
    }
  }
  {
    position: {
      x: 8
      y: 0
      colSpan: 8
      rowSpan: 2
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Overall resources compliance score'
          isOptional: true
        }
        {
          name: 'query'
          value: varResourceComplianceScoreQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQuerySingleValueTile'
      settings: {}
      partHeader: {
        title: 'Overall resources compliance score'
        subtitle: 'Percent of resources compliant with all policies in the SLZ'
      }
    }
  }
  {
    position: {
      x: 0
      y: 2
      colSpan: 8
      rowSpan: 2
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Overall data residency compliance score'
          isOptional: true
        }
        {
          name: 'query'
          value: varDataResidencyScoreQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQuerySingleValueTile'
      settings: {}
      partHeader: {
        title: 'Overall data residency compliance score'
        subtitle: 'Percent of resources compliant with data residency policies in the SLZ'
      }
    }
  }
  {
    position: {
      x: 8
      y: 2
      colSpan: 8
      rowSpan: 2
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Overall confidential compliance score'
          isOptional: true
        }
        {
          name: 'query'
          value: varConfidentialityScoreQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQuerySingleValueTile'
      settings: {}
      partHeader: {
        title: 'Overall confidential compliance score'
        subtitle: 'Percent of resources compliant with encryption and confidential computing policies in the SLZ'
      }
    }
  }
  {
    position: {
      x: 0
      y: 4
      colSpan: 16
      rowSpan: 1
    }
    metadata: {
      inputs: []
      type: 'Extension/HubsExtension/PartType/MarkdownPart'
      settings: {
        content: {
          settings: {
            content: ''
            title: 'Policy compliance'
            subtitle: ''
            markdownSource: 1
            markdownUri: null
          }
        }
      }
      partHeader: {}
    }
  }
  {
    position: {
      x: 0
      y: 5
      colSpan: 6
      rowSpan: 8
    }
    metadata: {
      inputs: [
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resource compliance by state'
          isOptional: true
        }
        {
          name: 'query'
          value: varResourcesbyComplianceStateQuery
          isOptional: true
        }
        {
          name: 'chartType'
          value: 2
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryChartTile'
      settings: {}
      partHeader: {
        title: 'Resource compliance by state'
        subtitle: 'Hover over bar to see percent of resources in each state'
      }
    }
  }
  {
    position: {
      x: 6
      y: 5
      colSpan: 10
      rowSpan: 4
    }
    metadata: {
      inputs: [
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resource compliance percentage by subscription'
          isOptional: true
        }
        {
          name: 'query'
          value: varCompliancebySubscriptionQuery
          isOptional: true
        }
        {
          name: 'chartType'
          value: 1
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryChartTile'
      settings: {}
      partHeader: {
        title: 'Resource compliance percentage by subscription'
        subtitle: 'Hover over bar to see subscription name and its compliance percentage'
      }
    }
  }
  {
    position: {
      x: 6
      y: 9
      colSpan: 10
      rowSpan: 4
    }
    metadata: {
      inputs: [
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resource compliance percentage by policy initiative'
          isOptional: true
        }
        {
          name: 'query'
          value: varCompliancebyPolicyInitiativeQuery
          isOptional: true
        }
        {
          name: 'chartType'
          value: 1
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryChartTile'
      settings: {}
      partHeader: {
        title: 'Resource compliance percentage by policy initiative'
        subtitle: 'Hover over bar to see policy initiative name and its compliance percentage'
      }
    }
  }
  {
    position: {
      x: 0
      y: 13
      colSpan: 16
      rowSpan: 4
    }
    metadata: {
      inputs: [
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resources compliance percentage by policy group name'
          isOptional: true
        }
        {
          name: 'query'
          value: varComplianceByPolicyGroupQuery
          isOptional: true
        }
        {
          name: 'chartType'
          value: 1
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryChartTile'
      settings: {}
      partHeader: {
        title: 'Resource compliance percentage by policy group name'
        subtitle: 'Hover over bar to see policy group name and its compliance percentage'
      }
    }
  }
  {
    position: {
      x: 0
      y: 17
      colSpan: 16
      rowSpan: 5
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Non-Compliant and exempt resources'
          isOptional: true
        }
        {
          name: 'query'
          value: varListofNonCompliantResourcesQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryGridTile'
      settings: {}
      partHeader: {
        title: 'Non-Compliant and exempt resources'
        subtitle: 'List of non-compliant and exempt resources for all policies in the SLZ'
      }
    }
  }
  {
    position: {
      x: 0
      y: 22
      colSpan: 16
      rowSpan: 1
    }
    metadata: {
      inputs: []
      type: 'Extension/HubsExtension/PartType/MarkdownPart'
      settings: {
        content: {
          settings: {
            content: ''
            title: 'Data residency compliance'
            subtitle: ''
            markdownSource: 1
            markdownUri: null
          }
        }
      }
      partHeader: {}
    }
  }
  {
    position: {
      x: 0
      y: 23
      colSpan: 5
      rowSpan: 5
    }
    metadata: {
      inputs: [
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Non-compliant resources by location'
          isOptional: true
        }
        {
          name: 'query'
          value: varResourcesOutsideofSafeRegionQuery
          isOptional: true
        }
        {
          name: 'chartType'
          value: 1
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryChartTile'
      settings: {}
      partHeader: {
        title: 'Non-Compliant resources by location'
        subtitle: 'These resources are in non-compliant locations per the data residency policy'
      }
    }
  }
  {
    position: {
      x: 5
      y: 23
      colSpan: 11
      rowSpan: 5
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resources exempt from data residency policies'
          isOptional: true
        }
        {
          name: 'query'
          value: varListofResourcesExemptofDataResidentPolicyQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryGridTile'
      settings: {}
      partHeader: {
        title: 'Resources exempt from data residency policies'
        subtitle: 'These resources are exempt from data residency policies'
      }
    }
  }
  {
    position: {
      x: 0
      y: 28
      colSpan: 16
      rowSpan: 5
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resources outside of approved regions'
          isOptional: true
        }
        {
          name: 'query'
          value: varListofResourcesOutsideofSafeRegionQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryGridTile'
      settings: {}
      partHeader: {
        title: 'Resources outside of approved regions'
        subtitle: 'These are the resources deployed outside of an approved region'
      }
    }
  }
  {
    position: {
      x: 0
      y: 33
      colSpan: 16
      rowSpan: 1
    }
    metadata: {
      inputs: []
      type: 'Extension/HubsExtension/PartType/MarkdownPart'
      settings: {
        content: {
          settings: {
            content: ''
            title: 'Confidential computing'
            subtitle: ''
            markdownSource: 1
            markdownUri: null
          }
        }
      }
      partHeader: {}
    }
  }
  {
    position: {
      x: 0
      y: 34
      colSpan: 5
      rowSpan: 2
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resource compliance score for encryption at rest policies'
          isOptional: true
        }
        {
          name: 'query'
          value: varComplianceScoreForStoragePolicyGroupQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQuerySingleValueTile'
      settings: {}
      partHeader: {
        title: 'Resource compliance score for encryption at rest policies'
        subtitle: 'Percent of resources compliant with encryption at rest policies in the SLZ'
      }
    }
  }
  {
    position: {
      x: 5
      y: 34
      colSpan: 5
      rowSpan: 2
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resource compliance score for encryption in transit policies'
          isOptional: true
        }
        {
          name: 'query'
          value: varComplianceScoreForTransportPolicyGroupQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQuerySingleValueTile'
      settings: {}
      partHeader: {
        title: 'Resource compliance score for encryption in transit policies'
        subtitle: 'Percent of resources compliant with encryption in transit policies in the SLZ'
      }
    }
  }
  {
    position: {
      x: 10
      y: 34
      colSpan: 6
      rowSpan: 2
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resource compliance score for confidential computing policies'
          isOptional: true
        }
        {
          name: 'query'
          value: varComplianceScoreForConfidentialComputingPolicyGroupQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQuerySingleValueTile'
      settings: {}
      partHeader: {
        title: 'Resource compliance score for confidential computing policies'
        subtitle: 'Percent of resources compliant with confidential computing policies in the SLZ'
      }
    }
  }
  {
    position: {
      x: 0
      y: 36
      colSpan: 16
      rowSpan: 5
    }
    metadata: {
      inputs: [
        {
          name: 'chartType'
          isOptional: true
        }
        {
          name: 'isShared'
          isOptional: true
        }
        {
          name: 'queryId'
          isOptional: true
        }
        {
          name: 'partTitle'
          value: 'Resources exempt from confidential computing policies'
          isOptional: true
        }
        {
          name: 'query'
          value: varListOfResourcesExemptOfConfidentialPoliciesQuery
          isOptional: true
        }
        {
          name: 'queryScope'
          value: {
            scope: 0
            values: []
          }
          isOptional: true
        }
      ]
      #disable-next-line BCP036
      type: 'Extension/HubsExtension/PartType/ArgQueryGridTile'
      settings: {}
      partHeader: {
        title: 'Resources exempt from confidential computing policies'
        subtitle: 'These resources are exempt from confidential computing policies'
      }
    }
  }
]

var varCustomTiles = loadJsonContent('../../custom/dashboard/compliance/tiles.json')
var varAllTiles = concat(varDefaultTitles, varCustomTiles)

resource resDashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: parDashboardName
  location: parLocation
  tags: parTags
  properties: {
    lenses: [
      {
        order: 0
        parts: [for part in varAllTiles: {
          position: {
            x: part.position.x
            y: part.position.y
            colSpan: part.position.colSpan
            rowSpan: part.position.rowSpan
          }
          metadata: {
            inputs: part.metadata.inputs
            #disable-next-line BCP036
            type: part.metadata.type
            settings: part.metadata.settings
            partHeader: empty(part.metadata.partHeader) ? part.metadata.partHeader : {}
          }
        }]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 24
              timeUnit: 1
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
      }
    }
  }
}
