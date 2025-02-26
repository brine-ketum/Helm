# Network Interface for vPacketStack (Management)
resource "azurerm_network_interface" "vpacketstack_mgmt_nic" {
  name                = var.vpb_mgmt_nic_name
  location            = azurerm_resource_group.plb_gwlb_rg.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name

  ip_configuration {
    name                          = var.vpacketstack_ipconfig_mgmt
    subnet_id                     = azurerm_subnet.mgmt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpacketstack_public_ip.id
  }

  lifecycle {
    ignore_changes = [ip_configuration]
  }
}

# CLM Network Security Group (Allow SSH and All Traffic)
resource "azurerm_network_security_group" "vpb_nsg" {
  name                = var.vpb_nsg
  location            = var.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}
# Network Interface for vPacketStack (Traffic)
resource "azurerm_network_interface" "vpacketstack_traffic_nic" {
  name                = var.vpb_traffic_nic_name
  location            = azurerm_resource_group.plb_gwlb_rg.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name

  ip_configuration {
    name                          = var.vpacketstack_ipconfig_traffic
    subnet_id                     = azurerm_subnet.traffic_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  lifecycle {
    ignore_changes = [ip_configuration]
  }
}

# Network Interface for vPacketStack (Tools)
resource "azurerm_network_interface" "vpacketstack_tools_nic" {
  name                = var.vpb_tools_nic_name
  location            = azurerm_resource_group.plb_gwlb_rg.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name

  ip_configuration {
    name                          = var.vpacketstack_ipconfig_tools
    subnet_id                     = azurerm_subnet.tools_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  lifecycle {
    ignore_changes = [ip_configuration]
  }
}

# vPacketStack VM
resource "azurerm_linux_virtual_machine" "vpacketstack_vm" {
  name                  = var.vpb_vm_name
  resource_group_name   = azurerm_resource_group.plb_gwlb_rg.name
  location              = azurerm_resource_group.plb_gwlb_rg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.vpacketstack_mgmt_nic.id,
    azurerm_network_interface.vpacketstack_traffic_nic.id,
    azurerm_network_interface.vpacketstack_tools_nic.id
  ]

  os_disk {
    caching              = var.os_disk_caching
    disk_size_gb         = var.os_disk_size_gb
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

# # Upload and execute the vPB installer script
#   provisioner "file" {
#     source      = var.vpb_installer_path  # Path to the local installer file
#     destination = "/home/${var.admin_username}/vPB-Installer.sh"

#     connection {
#       type        = "ssh"
#       host        = azurerm_public_ip.vpacketstack_public_ip.ip_address
#       user        = var.admin_username
#       password    = var.admin_password
#       timeout     = "60m"
#     }
#   }

  # provisioner "remote-exec" {
  #   inline = [
  #     "echo 'File upload complete: vPB installer script uploaded to /home/${var.admin_username}/vPB-Installer.sh'",

  #     "echo 'Making vPB installer script executable...'",
  #     "sudo chmod +x /home/${var.admin_username}/vPB-Installer.sh",
  #     "echo 'vPB installer script is now executable'",

  #     "echo 'Starting vPB installation...'",
  #     "/home/${var.admin_username}/vPB-Installer.sh",

  #     "echo 'vPB installation completed successfully!'"
  #   ]

  #   connection {
  #     type        = "ssh"
  #     host        = azurerm_public_ip.vpacketstack_public_ip.ip_address
  #     user        = var.admin_username
  #     password    = var.admin_password
  #     timeout     = "60m"
  #   }
  # }

  tags = {
    Name = var.vpb_vm_name
    Env  = var.env
  }
}

# Public IP for VM (for SSH access or management)
resource "azurerm_public_ip" "vpacketstack_public_ip" {
  name                = var.vpacketstack_public_ip_name
  location            = azurerm_resource_group.plb_gwlb_rg.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


