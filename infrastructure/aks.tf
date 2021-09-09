resource "azurerm_kubernetes_cluster" "integration" {
  name                = "integration-aks"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  dns_prefix          = "integration-aks"

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_B2ms"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "Standard"
  }

  private_cluster_enabled = true

}


output "client_certificate" {
  value     = azurerm_kubernetes_cluster.integration.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.integration.kube_config_raw
  sensitive = true
}
