### Simplified Terraform Configuration: PLB, Web Servers, and Tool VM Only ###

# Provider and Resource Group
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

resource "azurerm_resource_group" "rg" {
  name     = "Keysight-AzureVTap-rg"
  location = "eastus2"
}

# VNet and Subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "VNet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "consumer_subnet" {
  name                 = "ConsumerBackendNet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

# resource "azurerm_subnet" "tool_subnet" {
#   name                 = "CLToolNet"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.1.3.0/24"]
# }

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}


# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway_ip" {
  name                = "NATGatewayPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# NAT Gateway (without public_ip_ids)
resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "NATGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

# Associate the Public IP with the NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

# Associate the NAT Gateway with the Web Server Subnet
resource "azurerm_subnet_nat_gateway_association" "consumer_nat_assoc" {
  subnet_id      = azurerm_subnet.consumer_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

# Standard Load Balancer
resource "azurerm_lb" "lb" {
  name                = "LoadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "FrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "GWLBBackendPool"
}

resource "azurerm_lb_probe" "health_probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "HealthProbe"
  port            = 80
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "http_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "HTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "FrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.health_probe.id
  disable_outbound_snat          = true
  idle_timeout_in_minutes        = 15
  enable_tcp_reset               = true
}

# NSG and Rules
resource "azurerm_network_security_group" "nsg" {
  name                = "NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "nsg_rule_http" {
  name                        = "NSGRuleHTTP"
  priority                    = 200
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

resource "azurerm_network_security_rule" "nsg_rule_ssh" {
  name                        = "NSGRuleSSH"
  priority                    = 201
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

# Web Servers and NICs
# Define your local template for cloud-init
locals {
  cloud_init_webserver = templatefile("${path.module}/cloud_init_webserver.tpl", {})
}

resource "azurerm_network_interface" "nic_vm1" {
  name                = "NicVM1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.consumer_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic_vm2" {
  name                = "NicVM2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.consumer_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "web_server1" {
  name                  = "WebServer1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_D2s_v3"
  admin_username        = "azureuser"
  admin_password        = "Keysight123456"
  zone                  = "1"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.nic_vm1.id]
  custom_data           = base64encode(local.cloud_init_webserver)
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
  tags = {
    fastpathenabled = "true"
  }
}

resource "azurerm_linux_virtual_machine" "web_server2" {
  name                  = "WebServer2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_D2s_v3"
  admin_username        = "azureuser"
  admin_password        = "Keysight123456"
  zone                  = "1"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.nic_vm2.id]
  custom_data           = base64encode(local.cloud_init_webserver)
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
  tags = {
    fastpathenabled = "true"
  }
}

# NAT Rules for SSH
resource "azurerm_lb_nat_rule" "ssh_vm1" {
  name                           = "SSHWebServer1"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60001
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

resource "azurerm_lb_nat_rule" "ssh_vm2" {
  name                           = "SSHWebServer2"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60002
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

# Associate NICs to NSG and LB
resource "azurerm_network_interface_security_group_association" "nic_vm1_nsg" {
  network_interface_id      = azurerm_network_interface.nic_vm1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_vm2_nsg" {
  network_interface_id      = azurerm_network_interface.nic_vm2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_nat_rule_association" "nic_vm1_nat" {
  network_interface_id  = azurerm_network_interface.nic_vm1.id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_vm1.id
}

resource "azurerm_network_interface_nat_rule_association" "nic_vm2_nat" {
  network_interface_id  = azurerm_network_interface.nic_vm2.id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_vm2.id
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_vm1_lb_pool" {
  network_interface_id    = azurerm_network_interface.nic_vm1.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_vm2_lb_pool" {
  network_interface_id    = azurerm_network_interface.nic_vm2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# Tool VM and Resources
resource "azurerm_public_ip" "tool_vm_public_ip" {
  name                = "ToolVM-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_network_interface" "tool_nic" {
  name                = "ToolNic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.consumer_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tool_vm_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "tool_vm_nsg" {
  network_interface_id      = azurerm_network_interface.tool_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "tool_vm" {
  name                  = "ToolVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  admin_password        = "Keysight123456"
  zone                  = "1"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.tool_nic.id]
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
 custom_data = base64encode(<<EOF
#!/bin/bash
apt update -y
apt install -y net-tools tcpdump ca-certificates curl gnupg lsb-release

# Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=\$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  \$(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker
EOF
)
}
# Outputs
output "load_balancer_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

output "tool_vm_public_ip" {
  value = azurerm_public_ip.tool_vm_public_ip.ip_address
}

output "ssh_instructions" {
  value = <<EOF
SSH to WebServer1: ssh azureuser@${azurerm_public_ip.lb_public_ip.ip_address} -p 60001
SSH to WebServer2: ssh azureuser@${azurerm_public_ip.lb_public_ip.ip_address} -p 60002
SSH to Tool VM:     ssh azureuser@${azurerm_public_ip.tool_vm_public_ip.ip_address}
EOF
}
