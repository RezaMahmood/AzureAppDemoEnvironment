terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.26"
    }
  }

  backend "azurerm" {
    resource_group_name  = "AzureAppDemo-tfstate"
    storage_account_name = "azappdemostate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"

  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_group_name     = "AzureAppDemo"
  location                = "southeastasia"
  eventHubNamespace       = "DataIngest"
  eventHubName            = "DataIngestHub"
  appServicePlanName      = "DataIngestPlan"
  appServiceName          = "DataIngestApp"
  applicationInsightsName = "AzureAppDemoInsights"
  funcAppName             = "DataIngestFunc"
  vnetName                = "DataIngestVnet"
  cosmosdb_accountname    = "dataingestacc"
  cosmosdb_databasename   = "dataingestdb"
  cosmosdb_containername  = "dataingestcoll"

}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "demo" {
  name     = local.resource_group_name
  location = local.location
}
