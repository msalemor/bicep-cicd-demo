# Bicep Git action CI/CD demo

## Objective

The objective of this repo is to demo and discuss the capabilities and advantages of deploying Azure services using Bicep using Git actions to different environments.

## Main Bicep concepts to explore

- Consistency in naming
- Consistency in deployment
- Parameters
- Variables
- Resources
- Dependencies

## Requiremeents

- Development experience (variables, conditional statements, control statements, etc.)
- DevOps experience (if you want to create the entire pipeline)

## Bicep template

```bicep
param location string = resourceGroup().location // Location for all resources
param domain string = 'contoso'
param env string = 'dev'
param shortloc string = 'eus'

// Name convention
var fulldomain = '${domain}${env}${shortloc}'
var fulldomainh = '${domain}-${env}-${shortloc}'

// App Service and Web App parameters
param webSiteName string = 'webapp${domain}${env}${shortloc}'
param sku string = 'F1' // The SKU of App Service Plan
param linuxFxVersion string = 'node|14-lts' // The runtime stack of web app
var appServicePlanName = 'asp-${domain}-${env}-${shortloc}'

// PostgreSQL parameters
param dbname string = 'posql-${domain}-${env}-${shortloc}'
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

// Deploy the App Service
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

// Deploy the Web App
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

// Deploy PostgreSQL
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
```


## Git Action template

```yaml
on: [workflow_dispatch]

name: Azure Bicep deployment
jobs:
  
  dev:
    name: Build and deploy to dev
    runs-on: ubuntu-latest
    steps:

      # Checkout code
    - uses: actions/checkout@main

      # Log into Azure
    - uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

      # Deploy Bicep file
    - name: deploy
      uses: azure/arm-deploy@v1
      with:
        subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION }}        
        resourceGroupName: ${{ secrets.AZURE_RG }}
        template: ./infrastructure/websqlapp/main.bicep
        parameters: env=dev adminUser=${{ secrets.adminUser }} adminPassword=${{ secrets.adminPassword }}
        failOnStdErr: false
        
  staging:
    needs: dev
    name: Build and deploy to qa
    environment:
      name: qa      
    runs-on: ubuntu-latest
    steps:
    
    - name: deploy
      uses: azure/arm-deploy@v1
      with:
        subscriptionId: ''        
        resourceGroupName: ''
        template: ./infrastructure/websqlapp/main.bicep
        parameters: env=qa
        failOnStdErr: false
```
