resource "azurerm_public_ip" "provisionerpip" {
  name                         = "provisionerpip"
  location                     = "West Europe"
  resource_group_name          = "${azurerm_resource_group.ubuntucloud.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "azureprovisioner"
}

resource "azurerm_network_security_group" "provisioner" {
  name                = "provisionerSecurityGroup1"
  location            = "West Europe"
  resource_group_name = "${azurerm_resource_group.ubuntucloud.name}"

  security_rule {
    name                       = "ssh-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "provisionernic" {
  name                      = "provisionernic"
  location                  = "West Europe"
  resource_group_name       = "${azurerm_resource_group.ubuntucloud.name}"
  network_security_group_id = "${azurerm_network_security_group.provisioner.id}"

  ip_configuration {
    name                          = "provisionerconfig"
    subnet_id                     = "${azurerm_subnet.ubuntucloud.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.2.50"
    public_ip_address_id          = "${azurerm_public_ip.provisionerpip.id}"
  }
}

resource "azurerm_virtual_machine" "provisioner" {
  name                  = "provisioner"
  location              = "West Europe"
  resource_group_name   = "${azurerm_resource_group.ubuntucloud.name}"
  network_interface_ids = ["${azurerm_network_interface.provisionernic.id}"]
  vm_size               = "Standard_A1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.10"
    version   = "latest"
  }

  storage_os_disk {
    name          = "provisioner"
    vhd_uri       = "${azurerm_storage_account.ubuntucloud.primary_blob_endpoint}${azurerm_storage_container.ubuntucloudvhds.name}/provisioneros.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "provisioner"
    admin_username = "azure"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azure/.ssh/authorized_keys"
      key_data = ""
    }
  }

  # Copies the file as the Administrator user using SSH
  provisioner "remote-exec" {
    inline = [
      "echo ${azurerm_virtual_machine.provisioner.location} > locationinfo",
      "sudo snap install conjure-up --classic",
    ]

    connection {
      host        = "${azurerm_public_ip.provisionerpip.fqdn}"
      type        = "ssh"
      user        = "azure"
      private_key = "${file("provisioner.private")}"
    }
  }
}
