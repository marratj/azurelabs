resource "azurerm_public_ip" "templatedc1pip" {
  name                         = "templatedc1pip"
  location                     = "westeurope"
  resource_group_name          = "${azurerm_resource_group.pskurstemplate.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "azurepskurstemplatedc1"

  tags {
    environment = "PowerShell Kurs"
  }
}

resource "azurerm_network_interface" "templatedc1nic" {
  name                      = "templatedc1nic"
  location                  = "westeurope"
  resource_group_name       = "${azurerm_resource_group.pskurstemplate.name}"
  network_security_group_id = "${azurerm_network_security_group.mgmt-inbound.id}"

  ip_configuration {
    name                          = "templatedc1config"
    subnet_id                     = "${azurerm_subnet.pskurstemplate.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.2.50"
    public_ip_address_id          = "${azurerm_public_ip.templatedc1pip.id}"
  }

  tags {
    environment = "PowerShell Kurs"
  }
}

resource "azurerm_virtual_machine" "templatedc1" {
  name                  = "templatedc1"
  location              = "westeurope"
  resource_group_name   = "${azurerm_resource_group.pskurstemplate.name}"
  network_interface_ids = ["${azurerm_network_interface.templatedc1nic.id}"]
  vm_size               = "Standard_A1_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name          = "templatedc1"
    vhd_uri       = "${azurerm_storage_account.pskurstemplate.primary_blob_endpoint}${azurerm_storage_container.pskurstemplatevhds.name}/templatedc1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "templatedc1"
    admin_username = "pskurs"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {
    provision_vm_agent = true

    winrm {
      protocol        = "https"
      certificate_url = "https://marratlabkeyvault.vault.azure.net/secrets/winrm-certificate/7bbffd957e0349f091bcfacedcbcf3ae"
    }
  }

  os_profile_secrets {
    source_vault_id = "/subscriptions/4ebf822a-74f5-41b1-8bee-ed77a70d9f5f/resourceGroups/keyvault/providers/Microsoft.KeyVault/vaults/marratlabkeyvault"

    vault_certificates {
      certificate_url   = "https://marratlabkeyvault.vault.azure.net/secrets/winrm-certificate/7bbffd957e0349f091bcfacedcbcf3ae"
      certificate_store = "My"
    }
  }

  tags {
    environment = "PowerShell Kurs"
  }
}

resource "azurerm_virtual_machine_extension" "createaddomain" {
  name                 = "createaddomain"
  location             = "westeurope"
  resource_group_name  = "${azurerm_resource_group.pskurstemplate.name}"
  virtual_machine_name = "${azurerm_virtual_machine.templatedc1.name}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.8"

  settings = <<SETTINGS
    {
        "fileUris": ["https://marratautomation.blob.core.windows.net/azure-vm-extensions/Install-DSC.ps1"],
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File Install-DSC.ps1"
    }
    SETTINGS
}
