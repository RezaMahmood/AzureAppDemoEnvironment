terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.26"
    }
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
  funcStorageAccountName  = "demodataingeststor"
  funcAppName             = "DataIngestFunc"


}

resource "random_string" "dataingeststor" {
  length  = 12
  special = false
}

resource "azurerm_resource_group" "demo" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_eventhub_namespace" "dataingest" {
  name                = local.eventHubNamespace
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  sku                 = "Basic"
  capacity            = 1
}

resource "azurerm_eventhub" "dataingest" {
  name                = local.eventHubName
  namespace_name      = azurerm_eventhub_namespace.dataingest.name
  resource_group_name = azurerm_resource_group.demo.name
  partition_count     = 1
  message_retention   = 1
}

resource "azurerm_app_service_plan" "dataingest" {
  name                = local.appServicePlanName
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "dataingest" {
  name                = local.appServiceName
  location            = azurerm_app_service_plan.dataingest.location
  resource_group_name = azurerm_app_service_plan.dataingest.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.dataingest.id

  site_config {
    dotnet_framework_version = "v5.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "key" = "value"
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_application_insights" "dataingest" {
  name                = local.applicationInsightsName
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  application_type    = "web"
}

output "instrumentation_key" {
  value     = azurerm_application_insights.dataingest.instrumentation_key
  sensitive = true
}

output "app_id" {
  value     = azurerm_application_insights.dataingest.app_id
  sensitive = true
}

resource "azurerm_storage_account" "dataingest" {
  name                     = random_string.dataingeststor.result
  resource_group_name      = azurerm_resource_group.demo.name
  location                 = azurerm_app_service_plan.dataingest.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "dataingest" {
  name                       = local.funcAppName
  location                   = azurerm_app_service_plan.dataingest.location
  resource_group_name        = azurerm_resource_group.demo.name
  app_service_plan_id        = azurerm_app_service_plan.dataingest.id
  storage_account_name       = azurerm_storage_account.dataingest.name
  storage_account_access_key = azurerm_storage_account.dataingest.primary_access_key
  os_type                    = "linux"
}
