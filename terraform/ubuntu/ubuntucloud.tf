resource "azurerm_resource_group" "ubuntucloud" {
  name     = "ubuntucloud"
  location = "West Europe"
}

resource "azurerm_storage_account" "ubuntucloud" {
  name                = "ubuntucloudazure"
  resource_group_name = "${azurerm_resource_group.ubuntucloud.name}"
  location            = "westeurope"
  account_type        = "Standard_LRS"

  tags {
    environment = "ubuntucloud"
  }
}

resource "azurerm_storage_container" "ubuntucloudvhds" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.ubuntucloud.name}"
  storage_account_name  = "${azurerm_storage_account.ubuntucloud.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_network" "ubuntucloud" {
  name                = "ubuntucloud-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = "${azurerm_resource_group.ubuntucloud.name}"
}

resource "azurerm_subnet" "ubuntucloud" {
  name                 = "default"
  resource_group_name  = "${azurerm_resource_group.ubuntucloud.name}"
  virtual_network_name = "${azurerm_virtual_network.ubuntucloud.name}"
  address_prefix       = "10.0.2.0/24"
}
