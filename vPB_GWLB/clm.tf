# CLM Network Security Group (Allow SSH and All Traffic)
resource "azurerm_network_security_group" "clm_nsg" {
  name                = var.clm_nsg
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

# NSG Association with CLM Subnet
resource "azurerm_subnet_network_security_group_association" "clm_nsg_assoc" {
  subnet_id                 = azurerm_subnet.traffic_subnet.id
  network_security_group_id = azurerm_network_security_group.clm_nsg.id
}

# CLM Public IP Address
resource "azurerm_public_ip" "clm_public_ip" {
  name                = "CLMPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# CLM Ubuntu VM NIC
resource "azurerm_network_interface" "clm_nic" {
  name                = var.clm_nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name

  ip_configuration {
    name                          = var.clm_ipconfig_name
    subnet_id                     = azurerm_subnet.traffic_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.clm_public_ip.id
  }

   lifecycle {
    prevent_destroy = false #destroys vm before destroying assocaited resources
  }

  depends_on = [
    azurerm_subnet.traffic_subnet,
    azurerm_lb.plb,
    azurerm_lb_backend_address_pool.plb_backend_pool
  ]
}

# Backend Pool Association for CLM NIC
resource "azurerm_network_interface_backend_address_pool_association" "clm_backend_pool_assoc" {
  network_interface_id            = azurerm_network_interface.clm_nic.id
  ip_configuration_name           = azurerm_network_interface.clm_nic.ip_configuration[0].name
  backend_address_pool_id         = azurerm_lb_backend_address_pool.plb_backend_pool.id
}

# CLM Ubuntu VM
resource "azurerm_linux_virtual_machine" "clm_vm" {
  name                  = var.clm_vm_name
  resource_group_name   = azurerm_resource_group.plb_gwlb_rg.name
  location              = var.location
  size                  = var.clm_vm_size  # 4 vCPUs, 16 GB RAM
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.clm_nic.id
  ]

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.clm_os_disk_size_gb  # At least 100 GB
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

 # Upload and execute the CloudLens installer script
provisioner "file" {
  source      = var.installer_path  # Path to the local installer file
  destination = "/home/${var.admin_username}/CloudLens-Installer.sh"

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.clm_public_ip.ip_address
    user        = var.admin_username
    password    = var.admin_password
    timeout     = "60m"
  }
}

provisioner "remote-exec" {
  inline = [
    "echo 'File upload complete: CloudLens installer script uploaded to /home/${var.admin_username}/CloudLens-Installer.sh'",
      "echo 'Making CloudLens installer script executable...'",
      "sudo chmod +x /home/${var.admin_username}/CloudLens-Installer.sh",
      "echo 'CloudLens installer script is now executable'",
      "echo 'Starting CloudLens installation...'",
      "/home/${var.admin_username}/CloudLens-Installer.sh",
      "echo 'CloudLens installation completed successfully!'"
  ]

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.clm_public_ip.ip_address
    user        = var.admin_username
    password    = var.admin_password
    timeout     = "60m"
  }
}

  tags = {
    Name = var.clm_vm_name
    Env  = var.env
  }

  depends_on = [
    azurerm_linux_virtual_machine.vpacketstack_vm,
    azurerm_network_interface.clm_nic,
    azurerm_network_interface_backend_address_pool_association.clm_backend_pool_assoc
  ]
}

