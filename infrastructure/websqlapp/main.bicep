param location string = resourceGroup().location // Location for all resources
param domain string = 'contoso'
param env string = 'dev'
param shortloc string = 'eus'
param webSiteName string = 'webapp${domain}${env}${shortloc}'
param sku string = 'F1' // The SKU of App Service Plan
param linuxFxVersion string = 'node|14-lts' // The runtime stack of web app
var appServicePlanName = 'asp-${domain}-${env}-${shortloc}'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}
