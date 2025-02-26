provider "azurerm" {
  features {}
  subscription_id = "16e5b426-6372-4975-908a-e4cc44ee3cab"
}

# Resource Group
resource "azurerm_resource_group" "demo_cloudlens_rg" {
  name     = "DemoCloudLensResourceGroup"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "demo_cloudlens_vnet" {
  name                = "demoCloudLensVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
}

# Subnet
resource "azurerm_subnet" "demo_cloudlens_public_subnet" {
  name                 = "demoCloudLensPublicSubnet"
  resource_group_name  = azurerm_resource_group.demo_cloudlens_rg.name
  virtual_network_name = azurerm_virtual_network.demo_cloudlens_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP addresses
resource "azurerm_public_ip" "demo_cloudlens_ubuntu_public_ip" {
  name                = "demoCloudLensUbuntuPublicIP"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "demo_cloudlens_windows_public_ip" {
  name                = "demoCloudLensWindowsIP"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "demo_cloudlens_rhel_public_ip" {
  name                = "demoCloudLensRHELPublicIP"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "demo_cloudlens_clm_public_ip" {
  name                = "demoCloudLensCLMPublicIP"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "demo_cloudlens_vpb_public_ip" {
  name                = "demoCloudLensVPBPublicIP"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
# Network Security Group
resource "azurerm_network_security_group" "demo_cloudlens_nsg" {
  name                = "demoCloudLensNSG"
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
  subnet_id                 = azurerm_subnet.demo_cloudlens_public_subnet.id
  network_security_group_id = azurerm_network_security_group.demo_cloudlens_nsg.id
}

# Network Interfaces
resource "azurerm_network_interface" "demo_cloudlens_ubuntu_nic" {
  name                = "demoCloudLensUbuntuNic"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.demo_cloudlens_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_cloudlens_ubuntu_public_ip.id
  }
}

resource "azurerm_network_interface" "demo_cloudlens_rhel_nic" {
  name                = "demoCloudLensRHELNic"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.demo_cloudlens_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_cloudlens_rhel_public_ip.id
  }
}

resource "azurerm_network_interface" "demo_cloudlens_clm_nic" {
  name                = "demoCloudLensCLMNic"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.demo_cloudlens_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_cloudlens_clm_public_ip.id
  }
}

resource "azurerm_network_interface" "demo_cloudlens_windows_nic" {
  name                = "demoCloudLensWindowsNic"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.demo_cloudlens_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_cloudlens_windows_public_ip.id
  }
}

resource "azurerm_network_interface" "demo_cloudlens_vpb_nic" {
  name                = "demoCloudLensVPBNic"
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.demo_cloudlens_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_cloudlens_vpb_public_ip.id
  }
}
# Virtual Machines
resource "azurerm_linux_virtual_machine" "demo_cloudlens_ubuntu_vm" {
  name                = "Ubuntu"
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  size                = "Standard_B1s"
  admin_username      = "brine"
  admin_password      = "Bravedemo123!"
  network_interface_ids = [
    azurerm_network_interface.demo_cloudlens_ubuntu_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt-get install nginx
  EOF
  )

  disable_password_authentication = false

  tags = {
    Name = "demoCloudLensUbuntuVM"
    Env  = "Development"
  }
}

resource "azurerm_linux_virtual_machine" "demo_cloudlens_rhel_vm" {
  name                = "RHEL"
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  size                = "Standard_B1s"
  admin_username      = "brine"
  admin_password      = "Bravedemo123!"
  network_interface_ids = [
    azurerm_network_interface.demo_cloudlens_rhel_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-LVM"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo yum install nginx
    sudo systemctl enable nginx.service
  EOF
  )

  disable_password_authentication = false

  tags = {
    Name = "demoCloudLensRHELVM"
    Env  = "Development"
  }
}

resource "azurerm_linux_virtual_machine" "demo_cloudlens_clm_vm" {
  name                = "CLM"
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  size                = "Standard_B1s"
  admin_username      = "brine"
  admin_password      = "Bravedemo123!"
  network_interface_ids = [
    azurerm_network_interface.demo_cloudlens_clm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt-get install nginx
  EOF
  )

  disable_password_authentication = false

  tags = {
    Name = "demoCloudLensCLMVM"
    Env  = "Development"
  }
}

resource "azurerm_windows_virtual_machine" "demo_cloudlens_windows_vm" {
  name                = "Windows"
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  size                = "Standard_B1s"
  admin_username      = "brine"
  admin_password      = "Bravedemo123!"
  network_interface_ids = [
    azurerm_network_interface.demo_cloudlens_windows_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {
    Name = "demoCloudLensWindowsVM"
    Env  = "Development"
  }
}

resource "azurerm_linux_virtual_machine" "demo_cloudlens_vpb_vm" {
  name                = "vPB"
  resource_group_name = azurerm_resource_group.demo_cloudlens_rg.name
  location            = azurerm_resource_group.demo_cloudlens_rg.location
  size                = "Standard_B1s"
  admin_username      = "brine"
  admin_password      = "Bravedemo123!"
  network_interface_ids = [
    azurerm_network_interface.demo_cloudlens_vpb_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt-get install nginx
  EOF
  )

  disable_password_authentication = false

  tags = {
    Name = "demoCloudLensVPBVM"
    Env  = "Development"
  }
}
# Outputs
output "demo_cloudlens_ubuntu_public_ip" {
  value = azurerm_public_ip.demo_cloudlens_ubuntu_public_ip.ip_address
}

output "demo_cloudlens_windows_public_ip" {
  value = azurerm_public_ip.demo_cloudlens_windows_public_ip.ip_address
}

output "demo_cloudlens_rhel_public_ip" {
  value = azurerm_public_ip.demo_cloudlens_rhel_public_ip.ip_address
}

output "demo_cloudlens_clm_public_ip" {
  value = azurerm_public_ip.demo_cloudlens_clm_public_ip.ip_address
}

output "demo_cloudlens_vpb_public_ip" {
  value = azurerm_public_ip.demo_cloudlens_vpb_public_ip.ip_address
}