# Extending the Compliance Dashboard

The SLZ [Compliance Dashboard](../10-Compliance-Dashboard.md) provides a singular Azure policy compliance view for every resource within the SLZ deployment. While this is a great starting point for viewing the default and built-in policies assigned with the SLZ, many governance teams want to also see their own policies in the same view. This can be achieved through a few ways.

## Overall and Subscription Compliance Views

For the most part, no customization needs to be done for the overall or subscription views as these queries will search for assignment and compliance results for every resource and subscription under the top-level management group so any additional policies will be picked up natively.

## Data Residency Views

The data residency views are created by filtering by compliance results for policies under initiatives in the `so.1 - data residency` group. Custom policy assignments can populate these views by creating the group name `so.1 - data residency` in the custom initiative and grouping relevant policies into it.

## Customer-Managed Keys and Confidential Computing Views

The confidential computing views are created by filtering by compliance results for policies under initiatives in one of the following groups: `so.3 - customer-managed keys` or `so.4 - azure confidential computing`. Custom policy assignments can populate these views by creating one or more of the above group names in the custom initiative and grouping relevant policies into it.

## Custom Tiles

When one of the above methods is not sufficient, additional tiles can be added to the SLZ Compliance Dashboard by adding these to the [tiles JSON](../../custom/dashboard/compliance/tiles.json) file. This JSON file takes [Azure Portal Dashboard](https://learn.microsoft.com/azure/azure-portal/azure-portal-dashboards) tiles and will append them to the compliance dashboard.

Worth noting that the `position.y` value for tile elements will need to be lower than the y-values already used by the compliance dashboard otherwise tile elements could be missing or moved. Checkout the [tiles sample](../../custom/dashboard/compliance/tiles-sample.json) for an example of this extension.

### [Microsoft Legal Notice](../NOTICE.md)
