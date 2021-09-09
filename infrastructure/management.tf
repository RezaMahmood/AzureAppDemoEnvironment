
variable "jumpboxusername" {
  description = "Jumpbox admin username"
  type        = string
  sensitive   = true
}

variable "jumpboxpassword" {
  description = "Jumpbox admin password"
  type        = string
  sensitive   = true
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.dataingest.name
  address_prefixes     = ["10.1.4.0/27"]
}

resource "azurerm_public_ip" "bastion" {
  name                = "bastion-ip"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "AzureDemoBastion"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = azurerm_virtual_network.dataingest.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "jumpbox-internal"
    subnet_id                     = azurerm_subnet.dataingest_default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "jumpbox" {
  name                     = "jumpbox-vm"
  resource_group_name      = azurerm_resource_group.demo.name
  location                 = azurerm_virtual_network.dataingest.location
  size                     = "Standard_B4ms"
  admin_username           = var.jumpboxusername
  admin_password           = var.jumpboxpassword
  enable_automatic_updates = true

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "jumpbox" {
  virtual_machine_id = azurerm_windows_virtual_machine.jumpbox.id
  location           = azurerm_windows_virtual_machine.jumpbox.location
  enabled            = true

  daily_recurrence_time = "1900"
  timezone              = "Singapore Standard Time"

  notification_settings {
    enabled = false
  }

}

