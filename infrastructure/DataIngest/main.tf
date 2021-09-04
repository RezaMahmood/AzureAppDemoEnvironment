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
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "dataingest" {
  app_service_id = azurerm_function_app.dataingest.id
  subnet_id      = azurerm_subnet.dataingest_integration.id
}

resource "azurerm_app_service" "dataingest" {
  name                = local.appServiceName
  location            = azurerm_app_service_plan.dataingest.location
  resource_group_name = azurerm_app_service_plan.dataingest.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.dataingest.id

  site_config {
    dotnet_framework_version = "v5.0"
  }

  app_settings = {
    "eventHubNamespace"              = "${azurerm_eventhub.dataingest.namespace_name}.servicebus.windows.net"
    "eventHubName"                   = "${azurerm_eventhub.dataingest.name}"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.dataingest.instrumentation_key}"
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
  name                     = format("dataingest%sstor", random_integer.ri.result)
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
  identity {
    type = "SystemAssigned"
  }
  version = "~3"

  app_settings = {
    "EventHubConnection__fullyQualifiedNamespace" = "${azurerm_eventhub_namespace.dataingest.name}.servicebus.windows.net"
    "EventHubName"                                = "${azurerm_eventhub.dataingest.name}"
    "CosmosAccountUri"                            = "${azurerm_cosmosdb_account.dataingest.endpoint}"
    "CosmosDatabaseId"                            = "${azurerm_cosmosdb_sql_database.dataingest.name}"
    "CosmosContainerId"                           = "${azurerm_cosmosdb_sql_container.dataingest.name}"
    "APPINSIGHTS_INSTRUMENTATIONKEY"              = "${azurerm_application_insights.dataingest.instrumentation_key}"
    "WEBSITE_RUN_FROM_PACKAGE"                    = 1
    "FUNCTIONS_WORKER_RUNTIME"                    = "dotnet"
    "FUNCTIONS_EXTENSION_VERSION"                 = "~3"
  }
}

resource "azurerm_virtual_network" "dataingest" {
  name                = local.vnetName
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "dataingest_integration" {
  name                 = "integration-subnet"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.dataingest.name
  address_prefixes     = ["10.1.3.0/27"]

  delegation {
    name = "appservice-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "dataingest_default" {
  name                 = "default-subnet"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.dataingest.name
  address_prefixes     = ["10.1.1.0/27"]
}

resource "azurerm_subnet" "dataingest_privatelink" {
  name                 = "privatelink-subnet"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.dataingest.name
  address_prefixes     = ["10.1.2.0/27"]

  enforce_private_link_endpoint_network_policies = true
}

// Create CosmosDB with Private endpoint
resource "azurerm_cosmosdb_account" "dataingest" {
  name                = format("%s-%s", local.cosmosdb_accountname, random_integer.ri.result)
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  public_network_access_enabled = false

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = azurerm_resource_group.demo.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "dataingest" {
  name                = local.cosmosdb_databasename
  resource_group_name = azurerm_resource_group.demo.name
  account_name        = azurerm_cosmosdb_account.dataingest.name
}

resource "azurerm_cosmosdb_sql_container" "dataingest" {
  name                  = local.cosmosdb_containername
  resource_group_name   = azurerm_resource_group.demo.name
  account_name          = azurerm_cosmosdb_account.dataingest.name
  database_name         = azurerm_cosmosdb_sql_database.dataingest.name
  partition_key_path    = "/id"
  partition_key_version = 1
}

resource "null_resource" "cosmosdb-appservice-rbac" {
  // Assign RBAC permissions for Function App to CosmosDB
  provisioner "local-exec" {
    command = <<EOD
                az cosmosdb sql role assignment create \
                --account-name ${azurerm_cosmosdb_account.dataingest.name} \
                --resource-group ${azurerm_resource_group.demo.name} \
                --scope "/" \
                --principal-id ${azurerm_function_app.dataingest.identity.0.principal_id} \
                --role-definition-id "00000000-0000-0000-0000-000000000002"
                EOD
  }

  depends_on = [
  azurerm_cosmosdb_account.dataingest, azurerm_app_service.dataingest]
}

resource "azurerm_private_endpoint" "dataingest_cosmos" {
  name                = format("%s-%s-endpoint", local.cosmosdb_accountname, random_integer.ri.result)
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  subnet_id           = azurerm_subnet.dataingest_privatelink.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dataingest-cosmos.id]
  }

  private_service_connection {
    name                           = format("%s-%s-connection", local.cosmosdb_accountname, random_integer.ri.result)
    private_connection_resource_id = azurerm_cosmosdb_account.dataingest.id
    is_manual_connection           = false
    subresource_names              = ["sql"]
  }
}

resource "azurerm_private_dns_zone" "dataingest-cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.demo.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dataingest-cosmos" {
  name                  = "sqlcosmosvnetlink"
  resource_group_name   = azurerm_resource_group.demo.name
  private_dns_zone_name = azurerm_private_dns_zone.dataingest-cosmos.name
  virtual_network_id    = azurerm_virtual_network.dataingest.id
}

// Assign the App Service permissions to write to EventHub
resource "azurerm_role_assignment" "appservice-eventhub-sender" {
  scope                = azurerm_eventhub.dataingest.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_app_service.dataingest.identity.0.principal_id

  depends_on = [
    azurerm_eventhub.dataingest, azurerm_app_service.dataingest
  ]
}

// Assign the Function App permissions to read from EventHub
resource "azurerm_role_assignment" "funcapp-eventhub-receiver" {
  scope                = azurerm_eventhub.dataingest.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_function_app.dataingest.identity.0.principal_id

  depends_on = [
    azurerm_function_app.dataingest, azurerm_eventhub.dataingest
  ]
}

