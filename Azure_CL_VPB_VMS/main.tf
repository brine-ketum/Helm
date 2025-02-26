provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "demo_cloudlens_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "demo_cloudlens_vnet" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
}

# Subnet
resource "azurerm_subnet" "demo_cloudlens_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.demo_cloudlens_rg.name
  virtual_network_name = azurerm_virtual_network.demo_cloudlens_vnet.name
  address_prefixes     = var.subnet_address_prefix
}

# Public IP addresses
resource "azurerm_public_ip" "public_ips" {
  for_each            = var.public_ips
  name                = each.value
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP addresses for second NICs (nic2)
resource "azurerm_public_ip" "second_public_ips" {
  for_each            = var.public_ips
  name                = "${each.value}-nic2-public-ip"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group
resource "azurerm_network_security_group" "demo_cloudlens_nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name

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

# NSG Association
resource "azurerm_subnet_network_security_group_association" "demo_cloudlens_nsg_assoc" {
  subnet_id                 = azurerm_subnet.demo_cloudlens_subnet.id
  network_security_group_id = azurerm_network_security_group.demo_cloudlens_nsg.id
}

# Network Interfaces
resource "azurerm_network_interface" "network_interfaces" {
  for_each            = var.public_ips
  name                = "${each.value}-nic"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.demo_cloudlens_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ips[each.key].id
  }
}

# Second NIC for Linux VMs (if required)
resource "azurerm_network_interface" "second_network_interfaces" {
  for_each            = var.public_ips
  name                = "${each.value}-nic-2"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name

  ip_configuration {
    name                          = "ipconfig2"
    subnet_id                     = azurerm_subnet.demo_cloudlens_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = null # Second NIC doesn't need public IP
  }

  lifecycle {
    ignore_changes = [ip_configuration]
  }
}
# Virtual Machines - Linux VMs
resource "azurerm_linux_virtual_machine" "linux_vms" {
  for_each = { for k, v in var.vm_settings : k => v if v.os_type == "Linux" }

  name                  = each.key
  resource_group_name   = azurerm_resource_group.demo_cloudlens_rg.name
  location              = azurerm_resource_group.demo_cloudlens_rg.location
  size                  = each.value.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password

# Assign multiple NICs based on VM type (VPB, CLM get 2 NICs, others 1 NIC)
  network_interface_ids = contains(["VPB", "clm"], each.key) ? [
    azurerm_network_interface.network_interfaces[each.key].id,
    azurerm_network_interface.second_network_interfaces[each.key].id
  ] : [
    azurerm_network_interface.network_interfaces[each.key].id
  ]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = each.value.os_disk_size_gb
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = "latest"
  }

  disable_password_authentication = false

  tags = {
    Name = each.key
    Env  = "demo"
  }
}

# Virtual Machines - Windows VMs
resource "azurerm_windows_virtual_machine" "windows_vms" {
  for_each = { for k, v in var.vm_settings : k => v if v.os_type == "Windows" }

  name                  = each.key
  resource_group_name   = azurerm_resource_group.demo_cloudlens_rg.name
  location              = azurerm_resource_group.demo_cloudlens_rg.location
  size                  = each.value.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.network_interfaces[each.key].id]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = each.value.os_disk_size_gb
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = "latest"
  }

  tags = {
    Name = each.key
    Env  = "demo"
  }
}


