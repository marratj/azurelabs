resource "azurerm_resource_group" "pskurstemplate" {
  name     = "pskurstemplate"
  location = "westeurope"

  tags {
    environment = "PowerShell Kurs"
  }
}

resource "azurerm_storage_account" "pskurstemplate" {
  name                = "azurepskurstemplate445"
  resource_group_name = "${azurerm_resource_group.pskurstemplate.name}"
  location            = "westeurope"
  account_type        = "Standard_LRS"

  tags {
    environment = "PowerShell Kurs"
  }
}

resource "azurerm_storage_container" "pskurstemplatevhds" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.pskurstemplate.name}"
  storage_account_name  = "${azurerm_storage_account.pskurstemplate.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_network" "pskurstemplate" {
  name                = "pskurstemplate-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.pskurstemplate.name}"

  tags {
    environment = "PowerShell Kurs"
  }
}

resource "azurerm_subnet" "pskurstemplate" {
  name                 = "default"
  resource_group_name  = "${azurerm_resource_group.pskurstemplate.name}"
  virtual_network_name = "${azurerm_virtual_network.pskurstemplate.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_security_group" "mgmt-inbound" {
  name                = "mgmt-inbound"
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.pskurstemplate.name}"

  security_rule {
    name                       = "rdp-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "winrm-inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "PowerShell Kurs"
  }
}
