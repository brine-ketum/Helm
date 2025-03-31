provider "azurerm" {
  features {}
  subscription_id = "16e5b426-6372-4975-908a-e4cc44ee3cab"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0, <5.0"
    }
  }
  required_version = ">=1.9.5"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-WebServers"
  location = "eastus2"
}

# VNet and Subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-web"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet_webserver3" {
  name                 = "subnet-webserver3"
  address_prefixes     = ["10.10.1.0/24"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "subnet_webtool" {
  name                 = "subnet-webtool"
  address_prefixes     = ["10.10.2.0/24"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "Allow-HTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Locals for cloud-init
locals {
  cloud_init_webserver3 = templatefile("${path.module}/cloud_init_webserver3.tpl", {})
  cloud_init_webtool    = templatefile("${path.module}/cloud_init_webtool.tpl", {})
}

# Public IPs
resource "azurerm_public_ip" "webserver3_ip" {
  name                = "ip-webserver3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "webtool_ip" {
  name                = "ip-webtool"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NICs
resource "azurerm_network_interface" "nic_webserver3" {
  name                = "nic-webserver3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_webserver3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webserver3_ip.id
  }
}

resource "azurerm_network_interface" "nic_webtool" {
  name                = "nic-webtool"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_webtool.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webtool_ip.id
  }
}

# NSG associations
resource "azurerm_network_interface_security_group_association" "nsg_webserver3" {
  network_interface_id      = azurerm_network_interface.nic_webserver3.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nsg_webtool" {
  network_interface_id      = azurerm_network_interface.nic_webtool.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# VMs
resource "azurerm_linux_virtual_machine" "webserver3" {
  name                            = "WebServer3"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_D2s_v3"
  admin_username                  = "azureuser"
  admin_password                  = "Keysight123456"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic_webserver3.id]
  custom_data                     = base64encode(local.cloud_init_webserver3)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "webtool" {
  name                            = "WebTool"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_D2s_v3"
  admin_username                  = "azureuser"
  admin_password                  = "Keysight123456"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic_webtool.id]
  custom_data                     = base64encode(local.cloud_init_webtool)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

#Wireshark

# Windows Subnet
resource "azurerm_subnet" "subnet_windows" {
  name                 = "subnet-windows"
  address_prefixes     = ["10.10.3.0/24"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Public IP
resource "azurerm_public_ip" "windows_vm_ip" {
  name                = "ip-windows-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC
resource "azurerm_network_interface" "nic_windows" {
  name                = "nic-windows-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_windows.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows_vm_ip.id
  }
}

# NSG Rules - Allow All Inbound and Outbound for Windows VM
resource "azurerm_network_security_rule" "allow_all_inbound_windows" {
  name                        = "Allow-All-Inbound-Windows"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow_all_outbound_windows" {
  name                        = "Allow-All-Outbound-Windows"
  priority                    = 130
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# NSG association
resource "azurerm_network_interface_security_group_association" "nsg_windows" {
  network_interface_id      = azurerm_network_interface.nic_windows.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# Windows VM
resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = "WiresharkVM"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D4s_v5"
  admin_username      = "winadmin"
  admin_password      = "Keysight!123456"
  network_interface_ids = [
    azurerm_network_interface.nic_windows.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }
}

# Output
output "windows_vm_rdp" {
  value = "RDP to WiresharkVM: ${azurerm_public_ip.windows_vm_ip.ip_address}:3389 (Username: winadmin, Password: Keysight!123456)"
}

output "webserver3_ip" {
  value = azurerm_public_ip.webserver3_ip.ip_address
}

output "webtool_ip" {
  value = azurerm_public_ip.webtool_ip.ip_address
}

output "ssh_instructions" {
  value = <<EOF
SSH into WebServer3:
  ssh azureuser@${azurerm_public_ip.webserver3_ip.ip_address}

SSH into WebTool:
  ssh azureuser@${azurerm_public_ip.webtool_ip.ip_address}
EOF
}
