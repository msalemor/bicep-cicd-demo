param location string = resourceGroup().location // Location for all resources
param domain string = 'contoso'
param env string = 'dev'
param shortloc string = 'eus'

// Naming convention
var fulldomain = '${domain}${env}${shortloc}'
var fulldomainh = '${domain}-${env}-${shortloc}'

// App Service and Web App parameters
param webSiteName string = 'webapp${fulldomain}'
param sku string = 'F1' // The SKU of App Service Plan
param linuxFxVersion string = 'node|14-lts' // The runtime stack of web app
var appServicePlanName = 'asp-${fulldomainh}'

// PostgreSQL parameters
param dbname string = 'posql-${fulldomainh}'
@description('Administrator user name')
@secure()
param adminUser string
@description('Administrator user password')
@secure()
param adminPassword string
@description('SKU tier')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'Basic'
@description('The family of hardware')
param skuFamily string = 'Gen5'
@description('The scale up/out capacity')
param skuCapacity int = skuTier == 'Basic' ? 2 : 4

var skuNamePrefix = skuTier == 'GeneralPurpose' ? 'GP' : (skuTier == 'Basic' ? 'B' : 'OM')
var skuName = '${skuNamePrefix}_${skuFamily}_${skuCapacity}'

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

resource pgsql 'Microsoft.DBForPostgreSQL/servers@2017-12-01' = {
  name: dbname
  location: location
  sku: {
    name: skuName
    tier: skuTier
    family: skuFamily
    capacity: skuCapacity
  }
  properties: {
    createMode: 'Default'
    administratorLogin: adminUser
    administratorLoginPassword: adminPassword
  }
}
