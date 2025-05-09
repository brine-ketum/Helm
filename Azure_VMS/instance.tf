
# Provider Block
provider "azurerm" {
  features {}
  subscription_id = "16e5b426-6372-4975-908a-e4cc44ee3cab"
}

# Resource Group - Renamed to BrineK
resource "azurerm_resource_group" "brinek_rg" {
  name     = "BrineK"
  location = "EastUS2"
}

# Virtual Network
resource "azurerm_virtual_network" "brinek_vnet" {
  name                = "brinekVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
}

# Subnet
resource "azurerm_subnet" "brinek_public_subnet" {
  name                 = "brinekPublicSubnet"
  resource_group_name  = azurerm_resource_group.brinek_rg.name
  virtual_network_name = azurerm_virtual_network.brinek_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP for Ubuntu VM
resource "azurerm_public_ip" "ubuntu_public_ip" {
  name                = "UbuntuPublicIP"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP for RHEL VM
# resource "azurerm_public_ip" "rhel_public_ip" {
#   name                = "RHELPublicIP"
#   location            = azurerm_resource_group.brinek_rg.location
#   resource_group_name = azurerm_resource_group.brinek_rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# Network Security Group (NSG)
resource "azurerm_network_security_group" "brinek_nsg" {
  name                = "BrinekNSG"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "40.143.44.44/32"
    destination_address_prefix = "*"
  }

# Allow HTTP from your IP
  security_rule {
    name                       = "AllowHTTPFromMyIP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "40.143.44.44/32"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHTTPToBitbucket"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7990"
    source_address_prefix      = "40.143.44.44/32"
    destination_address_prefix = "*"
  }

# For Terraform NSG
security_rule {
  name                       = "AllowPgAdmin"
  priority                   = 130
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "5050"
  source_address_prefix      = "40.143.44.44/32"
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

# NSG Association with Subnet
resource "azurerm_subnet_network_security_group_association" "brinek_nsg_assoc" {
  subnet_id                 = azurerm_subnet.brinek_public_subnet.id
  network_security_group_id = azurerm_network_security_group.brinek_nsg.id
}

# # Network Interface for Ubuntu VM
resource "azurerm_network_interface" "ubuntu_nic" {
  name                = "UbuntuNIC"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.brinek_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu_public_ip.id
  }
}


resource "azurerm_public_ip" "ubuntu_lb_pip" {
  name                = "UbuntuLBFIP"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "ubuntu_lb" {
  name                = "UbuntuLB"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "FrontEnd"
    public_ip_address_id = azurerm_public_ip.ubuntu_lb_pip.id
  }
}


resource "azurerm_lb_nat_rule" "ssh_ubuntu" {
  name                           = "SSHUbuntu"
  resource_group_name            = azurerm_resource_group.brinek_rg.name
  loadbalancer_id                = azurerm_lb.ubuntu_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60022
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}


resource "azurerm_network_interface_nat_rule_association" "ubuntu_nat" {
  network_interface_id  = azurerm_network_interface.ubuntu_nic.id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_ubuntu.id
}

# Network Interface for RHEL VM
# resource "azurerm_network_interface" "rhel_nic" {
#   name                = "RHELNIC"
#   location            = azurerm_resource_group.brinek_rg.location
#   resource_group_name = azurerm_resource_group.brinek_rg.name

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.brinek_public_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.rhel_public_ip.id
#   }
# }

# # Ubuntu Linux VM
resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  name                = "UbuntuVM"
  resource_group_name = azurerm_resource_group.brinek_rg.name
  location            = azurerm_resource_group.brinek_rg.location
  size                = "Standard_D4s_v3"
  admin_username      = "brine"
  admin_password      = "Bravedemo123!"
  network_interface_ids = [
    azurerm_network_interface.ubuntu_nic.id,
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
    sudo apt-get install -y nginx
  EOF
  )

  disable_password_authentication = false

  tags = {
    Name = "UbuntuVM"
    Env  = "Development"
  }
}


resource "azurerm_lb_nat_rule" "bitbucket_ui" {
  name                           = "BitbucketUI"
  resource_group_name            = azurerm_resource_group.brinek_rg.name
  loadbalancer_id                = azurerm_lb.ubuntu_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60090
  backend_port                   = 7990
  frontend_ip_configuration_name = "FrontEnd"
}

resource "azurerm_network_interface_nat_rule_association" "bitbucket_ui_assoc" {
  network_interface_id  = azurerm_network_interface.ubuntu_nic.id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.bitbucket_ui.id
}

# RHEL Linux VM
# resource "azurerm_linux_virtual_machine" "rhel_vm" {
#   name                = "RHELVM"
#   resource_group_name = azurerm_resource_group.brinek_rg.name
#   location            = azurerm_resource_group.brinek_rg.location
#   size                = "Standard_D4s_v3"
#   admin_username      = "brine"
#   admin_password      = "Bravedemo123!"
#   network_interface_ids = [
#     azurerm_network_interface.rhel_nic.id,
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     disk_size_gb         = 127
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "RedHat"
#     offer     = "RHEL"
#     sku       = "8-LVM"
#     version   = "latest"
#   }

# Run sudo firewall-cmd --permanent --add-service=http
# sudo firewall-cmd --reload
# sudo firewall-cmd --list-all

# custom_data = base64encode(<<-EOF
#   #!/bin/bash
#   sudo yum update -y
#   sudo yum install httpd -y
#   sudo systemctl enable httpd
#   sudo systemctl start httpd
# EOF
# )
#   disable_password_authentication = false

#   tags = {
#     Name = "RHELVM"
#     Env  = "Development"
#   }
# }

# Output Public IPs
output "ubuntu_public_ip" {
  value = azurerm_public_ip.ubuntu_public_ip.ip_address
}

# output "rhel_public_ip" {
#   value = azurerm_public_ip.rhel_public_ip.ip_address
# }

#SSH to RHEL VM: ssh brine@${azurerm_public_ip.rhel_public_ip.ip_address}
output "ssh_instructions" {
  value = <<EOF
SSH to Ubuntu VM: ssh brine@${azurerm_public_ip.ubuntu_public_ip.ip_address}
SSH to Ubuntu VM: ssh brine@${azurerm_public_ip.ubuntu_lb_pip.ip_address} -p 60022

EOF
}
