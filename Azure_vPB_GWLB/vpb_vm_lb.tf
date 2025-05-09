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
  name     = "Brine"
  location = "eastus2"
}

# Use the existing Azure Virtual Network "Cyperf-virtualnetwork"
resource "azurerm_virtual_network" "vtap_vnet" {
  name                = "Vtap-Vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["172.16.0.0/16"]
}

# Define source subnet 172.16.3.0/24 (source subnet)
resource "azurerm_subnet" "source_subnet" {
  name                 = "SourceSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vtap_vnet.name
  address_prefixes     = ["172.16.3.0/24"]
  # Associate with NAT Gateway later if needed (update below)
}

# Define destination subnet 172.16.4.0/24 (destination subnet for Suricata IDS)
resource "azurerm_subnet" "destination_subnet" {
  name                 = "DestinationSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vtap_vnet.name
  address_prefixes     = ["172.16.4.0/24"]
}

# Other subnets updated to use address space 172.16.x.x per your setup
resource "azurerm_subnet" "consumer_subnet" {
  name                 = "ConsumerBackendNet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vtap_vnet.name
  address_prefixes     = ["172.16.10.0/24"]
}

resource "azurerm_subnet" "vpb_mgmt" {
  name                 = "VPBManagement"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vtap_vnet.name
  address_prefixes     = ["172.16.20.0/24"]
}

resource "azurerm_subnet" "vpb_ingress" {
  name                 = "VPBIngress"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vtap_vnet.name
  address_prefixes     = ["172.16.21.0/24"]
}

resource "azurerm_subnet" "vpb_egress" {
  name                 = "VPBEgress"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vtap_vnet.name
  address_prefixes     = ["172.16.22.0/24"]
}

resource "azurerm_subnet" "tool" {
  name                 = "Tool"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vtap_vnet.name
  address_prefixes     = ["172.16.23.0/24"]
}

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

# NAT Gateway with Public IP
resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "NATGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

# Associate the NAT Gateway with the source subnet (adjust as needed)
resource "azurerm_subnet_nat_gateway_association" "source_nat_assoc" {
  subnet_id      = azurerm_subnet.source_subnet.id
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
  source_address_prefix       = "40.143.44.44"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "nsg_rule_https" {
  name                        = "NSGRuleHTTPS"
  priority                    = 203
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "40.143.44.44"
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
  source_address_prefix       = "40.143.44.44"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
locals {
  cloud_init_webserver = templatefile("${path.module}/cloud_init_webserver.tpl", {})
}
# Web Server VM with Two NICs: source and destination subnets

# NIC for Source Subnet 172.16.3.0/24
resource "azurerm_network_interface" "nic_vm1_source" {
  name                = "NicVM1-Source"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_forwarding_enabled = true
  # auxiliary_mode      = "MaxConnections"  # Choose the appropriate mode
  auxiliary_mode      = "AcceleratedConnections"
  auxiliary_sku       = "A2"  
  ip_configuration {
    name                          = "ipconfig-source"
    subnet_id                     = azurerm_subnet.source_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    fastpathenabled = "TRUE" #Not required for public preview
  }
}

# NIC for Destination Subnet 172.16.4.0/24
resource "azurerm_network_interface" "nic_vm1_destination" {
  name                = "NicVM1-Destination"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_forwarding_enabled = true
  # auxiliary_mode      = "MaxConnections"  # Choose the appropriate mode 
  auxiliary_mode      = "AcceleratedConnections"
  auxiliary_sku       = "A2"  
 
  ip_configuration {
    name                          = "ipconfig-destination"
    subnet_id                     = azurerm_subnet.destination_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    fastpathenabled = "TRUE"
  }
}

# Associate NICs with NSG
resource "azurerm_network_interface_security_group_association" "nic_vm1_source_nsg" {
  network_interface_id      = azurerm_network_interface.nic_vm1_source.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_vm1_destination_nsg" {
  network_interface_id      = azurerm_network_interface.nic_vm1_destination.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# WebServer1 VM with two NICs assigned
resource "azurerm_linux_virtual_machine" "web_server1" {
  name                  = "WebServer1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_D4s_v3"
  admin_username        = "azureuser"
  admin_password        = "Keysight123456"
  zone                  = "1"
  disable_password_authentication = false

  # Attach source subnet NIC as primary, destination subnet NIC as secondary
  network_interface_ids = [
    azurerm_network_interface.nic_vm1_source.id,
    azurerm_network_interface.nic_vm1_destination.id
  ]

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
    fastpathenabled = "TRUE"
  }
}


# NAT Rules for SSH


resource "azurerm_lb_nat_rule" "ssh_vm1_source" {
  name                           = "SSHSrc"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60001
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

resource "azurerm_lb_nat_rule" "ssh_vm1_destination" {
  name                           = "SSHDest"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60002
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

resource "azurerm_network_interface_nat_rule_association" "nic_vm1_source_nat" {
  network_interface_id  = azurerm_network_interface.nic_vm1_source.id
  ip_configuration_name = "ipconfig-source"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_vm1_source.id
}

resource "azurerm_network_interface_nat_rule_association" "nic_vm1_destination_nat" {
  network_interface_id  = azurerm_network_interface.nic_vm1_destination.id
  ip_configuration_name = "ipconfig-destination"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_vm1_destination.id
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_vm1_lb_pool_source" {
  network_interface_id    = azurerm_network_interface.nic_vm1_source.id
  ip_configuration_name   = "ipconfig-source"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_vm1_lb_pool_destination" {
  network_interface_id    = azurerm_network_interface.nic_vm1_destination.id
  ip_configuration_name   = "ipconfig-destination"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}


resource "azurerm_network_security_rule" "nsg_rule_tcp_3000" {
  name                        = "AllowTCP3000"
  priority                    = 202
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3000"
  source_address_prefix       = "40.143.44.44"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "nsg_allow_outbound_internet" {
  name                        = "AllowInternetOut"
  priority                    = 310
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}


# Tool VM and Resources updated to Tool Subnet 172.16.23.0/24
resource "azurerm_public_ip" "ntop_tool1_public_ip" {
  name                = "ntop_tool1-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}
resource "azurerm_network_interface" "ntop_tool1_nic" {
  name                = "ntop_tool1Nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tool.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ntop_tool1_public_ip.id
  }
}
resource "azurerm_network_interface_security_group_association" "ntop_tool1_nsg" {
  network_interface_id      = azurerm_network_interface.ntop_tool1_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_linux_virtual_machine" "ntop_tool1_vm" {
  name                  = "ntop_tool1"
  computer_name         = "ntoptool1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_D8s_v3"
  admin_username        = "azureuser"
  admin_password        = "Keysight123456"
  zone                  = "1"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.ntop_tool1_nic.id]
os_disk {
  caching              = "ReadWrite"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 200
}

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_lb_nat_rule" "ssh_ntop_tool1" {
  name                           = "SSHntopTool1"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60004
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

resource "azurerm_network_interface_nat_rule_association" "ntop_tool1_nat" {
  network_interface_id  = azurerm_network_interface.ntop_tool1_nic.id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_ntop_tool1.id
}
#Ntop2

# Public IP for Suricata2 VM
resource "azurerm_public_ip" "ntop_tool2_public_ip" {
  name                = "ntop_tool2-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# NIC for ntop2 VM
resource "azurerm_network_interface" "ntop_tool2_nic" {
  name                = "ntop_tool2Nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tool.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ntop_tool2_public_ip.id
  }
}

# Attach NIC to NSG
resource "azurerm_network_interface_security_group_association" "ntop_tool2_nsg" {
  network_interface_id      = azurerm_network_interface.ntop_tool2_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Suricata2 Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "ntop_tool2_vm" {
  name                  = "ntop_tool2"
  computer_name         = "ntoptool2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_D8s_v3"
  admin_username        = "azureuser"
  admin_password        = "Keysight123456"
  zone                  = "1"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.ntop_tool2_nic.id]
os_disk {
  caching              = "ReadWrite"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 200
}

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# NAT Rule for ntop2 SSH Access through Load Balancer
resource "azurerm_lb_nat_rule" "ssh_ntop_tool2" {
  name                           = "SSHntopTool2"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60005
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

resource "azurerm_network_interface_nat_rule_association" "ntop_tool2_nat" {
  network_interface_id  = azurerm_network_interface.ntop_tool2_nic.id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_ntop_tool2.id
}

# resource "azurerm_network_security_rule" "nsg_allow_vxlan" {
#   name                        = "AllowVXLANUDP"
#   priority                    = 203
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Udp"
#   source_port_range           = "*"
#   destination_port_range      = "4789"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.nsg.name
# }


# VPB NSG and NICs updated address ranges to 172.16.x.x
resource "azurerm_network_security_group" "vpb_nsg" {
  name                = "VPB-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "vpb_allow_all_in" {
  name                        = "AllowAllIn"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "0.0.0.0/0"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vpb_nsg.name
}

resource "azurerm_network_security_rule" "vpb_allow_tcp_out" {
  name                        = "AllowAllTCPOut"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "0.0.0.0/0"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vpb_nsg.name
}

resource "azurerm_network_security_rule" "vpb_allow_vxlan_in" {
  name                        = "AllowVXLANIn"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_ranges     = ["4789"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vpb_nsg.name
}

resource "azurerm_network_security_rule" "vpb_allow_http" {
  name                        = "AllowHTTPWebTraffic"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vpb_nsg.name
}

resource "azurerm_network_security_rule" "vpb_allow_ssh" {
  name                        = "AllowVPB2SSH"
  priority                    = 111
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*" # Or your IP
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vpb_nsg.name
}


resource "azurerm_public_ip" "vpb_public_ip" {
  name                = "VPB-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_network_interface" "vpb_nic1" {
  name                = "VPBNic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vpb_mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpb_public_ip.id
  }
}

resource "azurerm_network_interface" "vpb_nic2" {
  name                           = "VPBIngress"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vpb_ingress.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "vpb_nic3" {
  name                           = "VPBEgress"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vpb_egress.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "vpb_nic1_nsg" {
  network_interface_id      = azurerm_network_interface.vpb_nic1.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
}

resource "azurerm_network_interface_security_group_association" "vpb_nic2_nsg" {
  network_interface_id      = azurerm_network_interface.vpb_nic2.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
}

resource "azurerm_network_interface_security_group_association" "vpb_nic3_nsg" {
  network_interface_id      = azurerm_network_interface.vpb_nic3.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
}

resource "azurerm_linux_virtual_machine" "vpb_vm" {
  name                  = "vPB"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_D8_v5"
  admin_username        = "vpb"
  admin_password        = "Keysight!123456"
  disable_password_authentication = false
  zone                  = "1"

  network_interface_ids = [
    azurerm_network_interface.vpb_nic1.id,
    azurerm_network_interface.vpb_nic2.id,
    azurerm_network_interface.vpb_nic3.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 150
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Script to install VPB
resource "null_resource" "vpb_install" {
  depends_on = [
    azurerm_linux_virtual_machine.vpb_vm,
    azurerm_network_interface_security_group_association.vpb_nic1_nsg,
    azurerm_network_interface.vpb_nic1
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [triggers]
  }

  triggers = {
    script_checksum = filesha256("/Users/brinketu/Downloads/vpb-3.9.0-42-install-package.sh")
  }

  # Upload the installer script
  provisioner "file" {
    source      = "/Users/brinketu/Downloads/vpb-3.9.0-42-install-package.sh"
    destination = "/home/vpb/vpb-installer.sh"

    connection {
      type     = "ssh"
      user     = "vpb"
      password = "Keysight!123456"
      host     = azurerm_public_ip.vpb_public_ip.ip_address
      timeout  = "10m"
    }
  }

  # Run the installer if not already done
  provisioner "remote-exec" {
    inline = [
      "ls -l /home/vpb",
      "sleep 10",
      "if [ ! -f /home/vpb/.vpb_installed ]; then",
      "  chmod +x /home/vpb/vpb-installer.sh",
      "  sudo bash /home/vpb/vpb-installer.sh",
      "  touch /home/vpb/.vpb_installed",
      "else",
      "  echo 'VPB already installed. Skipping...'",
      "fi"
    ]

    connection {
      type     = "ssh"
      user     = "vpb"
      password = "Keysight!123456"
      host     = azurerm_public_ip.vpb_public_ip.ip_address
      timeout  = "45m"
    }
  }
}


#Add code 

# VPB2 Public IP
resource "azurerm_public_ip" "vpb2_public_ip" {
  name                = "VPB2-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# VPB2 NICs
resource "azurerm_network_interface" "vpb2_nic1" {
  name                = "VPB2Nic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vpb_mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpb2_public_ip.id
  }
}

resource "azurerm_network_interface" "vpb2_nic2" {
  name                           = "VPB2Ingress"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_forwarding_enabled          = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vpb_ingress.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "vpb2_nic3" {
  name                           = "VPB2Egress"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  ip_forwarding_enabled          = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vpb_egress.id
    private_ip_address_allocation = "Dynamic"
  }
}

# NIC - NSG Associations
resource "azurerm_network_interface_security_group_association" "vpb2_nic1_nsg" {
  network_interface_id      = azurerm_network_interface.vpb2_nic1.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
}
resource "azurerm_network_interface_security_group_association" "vpb2_nic2_nsg" {
  network_interface_id      = azurerm_network_interface.vpb2_nic2.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
}
resource "azurerm_network_interface_security_group_association" "vpb2_nic3_nsg" {
  network_interface_id      = azurerm_network_interface.vpb2_nic3.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
}

# VPB2 Linux VM
resource "azurerm_linux_virtual_machine" "vpb_vm2" {
  name                  = "vPB2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_D8_v5"
  admin_username        = "vpb"
  admin_password        = "Keysight!123456"
  disable_password_authentication = false
  zone                  = "1"

  network_interface_ids = [
    azurerm_network_interface.vpb2_nic1.id,
    azurerm_network_interface.vpb2_nic2.id,
    azurerm_network_interface.vpb2_nic3.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 150
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# VPB2 Install Script
resource "null_resource" "vpb2_install" {
depends_on = [
  azurerm_network_security_group.vpb_nsg,
  azurerm_network_security_rule.vpb_allow_ssh,
  azurerm_network_interface_security_group_association.vpb2_nic1_nsg,
  azurerm_linux_virtual_machine.vpb_vm2
]


  lifecycle {
    create_before_destroy = true
    ignore_changes        = [triggers]
  }

  triggers = {
    script_checksum = filesha256("/Users/brinketu/Downloads/vpb-3.9.0-42-install-package.sh")
  }

  provisioner "file" {
    source      = "/Users/brinketu/Downloads/vpb-3.9.0-42-install-package.sh"
    destination = "/home/vpb/vpb-installer.sh"

    connection {
      type     = "ssh"
      user     = "vpb"
      password = "Keysight!123456"
      host     = azurerm_public_ip.lb_public_ip.ip_address
      port = 60006
      timeout  = "10m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "ls -l /home/vpb",
      "sleep 60",
      "if [ ! -f /home/vpb/.vpb_installed ]; then",
      "  chmod +x /home/vpb/vpb-installer.sh",
      "  sudo bash /home/vpb/vpb-installer.sh",
      "  touch /home/vpb/.vpb_installed",
      "else",
      "  echo 'VPB2 already installed. Skipping...'",
      "fi"
    ]

    connection {
      type     = "ssh"
      user     = "vpb"
      password = "Keysight!123456"
      host     = azurerm_public_ip.lb_public_ip.ip_address
      port = 60006
      timeout  = "10m"
    }
  }
}
# ILB Backend Pool Associations for VPBs
resource "azurerm_network_interface_backend_address_pool_association" "vpb1_ingress_pool" {
  network_interface_id    = azurerm_network_interface.vpb_nic2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ilb_backend_pool.id
}
resource "azurerm_network_interface_backend_address_pool_association" "vpb2_ingress_pool" {
  network_interface_id    = azurerm_network_interface.vpb2_nic2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ilb_backend_pool.id
}

# Internal Load Balancer for Ingress Traffic
resource "azurerm_lb" "ilb" {
  name                = "ILB-VPBIngress"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "ILBFrontend"
    subnet_id                     = azurerm_subnet.vpb_ingress.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.16.21.10"
  }
}

resource "azurerm_lb_backend_address_pool" "ilb_backend_pool" {
  loadbalancer_id = azurerm_lb.ilb.id
  name            = "IngressPool"
}

resource "azurerm_lb_probe" "ilb_health_probe" {
  loadbalancer_id = azurerm_lb.ilb.id
  name            = "ILBHealthProbe"
  port            = 80
  protocol        = "Tcp"
}


resource "azurerm_lb_rule" "ilb_rule" {
  loadbalancer_id                = azurerm_lb.ilb.id
  name                           = "ILBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "ILBFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ilb_backend_pool.id]
  probe_id                       = azurerm_lb_probe.ilb_health_probe.id
  disable_outbound_snat          = true
  idle_timeout_in_minutes        = 15
  enable_tcp_reset               = true
}

resource "azurerm_lb_rule" "vxlan_rule" {
  loadbalancer_id                = azurerm_lb.ilb.id
  name                           = "VXLANRule"
  protocol                       = "Udp"
  frontend_port                  = 4789
  backend_port                   = 4789
  frontend_ip_configuration_name = "ILBFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ilb_backend_pool.id]
  probe_id                       = azurerm_lb_probe.ilb_health_probe.id  # You may define a separate UDP probe
  disable_outbound_snat          = true
  idle_timeout_in_minutes        = 15
  enable_tcp_reset               = false  # Only relevant for TCP
}

resource "azurerm_lb_nat_rule" "ssh_vpb2" {
  name                           = "SSHVPB2"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 60006
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

resource "azurerm_network_interface_nat_rule_association" "vpb2_nat" {
  network_interface_id  = azurerm_network_interface.vpb2_nic1.id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_vpb2.id
}


#vPB3 
# resource "azurerm_public_ip" "vpb3_public_ip" {
#   name                = "VPB3-PublicIP"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["1", "2", "3"]
# }


# resource "azurerm_network_interface" "vpb3_nic1" {
#   name                = "VPB3Nic1"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.vpb_mgmt.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.vpb3_public_ip.id
#   }
# }

# resource "azurerm_network_interface" "vpb3_nic2" {
#   name                = "VPB3Ingress"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   accelerated_networking_enabled = true
#   ip_forwarding_enabled = true
#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.vpb_ingress.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# resource "azurerm_network_interface" "vpb3_nic3" {
#   name                = "VPB3Egress"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   accelerated_networking_enabled = true
#   ip_forwarding_enabled = true
#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.vpb_egress.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# resource "azurerm_network_interface_security_group_association" "vpb3_nic1_nsg" {
#   network_interface_id      = azurerm_network_interface.vpb3_nic1.id
#   network_security_group_id = azurerm_network_security_group.vpb_nsg.id
# }

# resource "azurerm_network_interface_security_group_association" "vpb3_nic2_nsg" {
#   network_interface_id      = azurerm_network_interface.vpb3_nic2.id
#   network_security_group_id = azurerm_network_security_group.vpb_nsg.id
# }

# resource "azurerm_network_interface_security_group_association" "vpb3_nic3_nsg" {
#   network_interface_id      = azurerm_network_interface.vpb3_nic3.id
#   network_security_group_id = azurerm_network_security_group.vpb_nsg.id
# }


# resource "azurerm_linux_virtual_machine" "vpb_vm3" {
#   name                = "vPB3"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   size                = "Standard_D8_v5"
#   admin_username      = "vpb"
#   admin_password      = "Keysight!123456"
#   disable_password_authentication = false
#   zone                = "1"

#   network_interface_ids = [
#     azurerm_network_interface.vpb3_nic1.id,
#     azurerm_network_interface.vpb3_nic2.id,
#     azurerm_network_interface.vpb3_nic3.id
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#     disk_size_gb         = 30
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }
# }

# resource "null_resource" "vpb3_install" {
#   depends_on = [
#     azurerm_network_security_group.vpb_nsg,
#     azurerm_network_security_rule.vpb_allow_ssh,
#     azurerm_network_interface_security_group_association.vpb3_nic1_nsg,
#     azurerm_linux_virtual_machine.vpb_vm3
#   ]

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [triggers]
#   }

#   triggers = {
#     script_checksum = filesha256("/Users/brinketu/Downloads/vpb-3.9.0-42-install-package.sh")
#   }

#   provisioner "file" {
#     source      = "/Users/brinketu/Downloads/vpb-3.9.0-42-install-package.sh"
#     destination = "/home/vpb/vpb-installer.sh"

#     connection {
#       type     = "ssh"
#       user     = "vpb"
#       password = "Keysight!123456"
#       host     = azurerm_public_ip.lb_public_ip.ip_address
#       port     = 60007
#       timeout  = "10m"
#     }
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "ls -l /home/vpb",
#       "sleep 60",
#       "if [ ! -f /home/vpb/.vpb_installed ]; then",
#       "  chmod +x /home/vpb/vpb-installer.sh",
#       "  sudo bash /home/vpb/vpb-installer.sh",
#       "  touch /home/vpb/.vpb_installed",
#       "else",
#       "  echo 'VPB3 already installed. Skipping...'",
#       "fi"
#     ]

#     connection {
#       type     = "ssh"
#       user     = "vpb"
#       password = "Keysight!123456"
#       host     = azurerm_public_ip.lb_public_ip.ip_address
#       port     = 60007
#       timeout  = "10m"
#     }
#   }
# }


# # NAT Rule for VPB3 SSH Access through Load Balancer
# resource "azurerm_lb_nat_rule" "ssh_vpb3" {
#   name                           = "SSHVPB3"
#   resource_group_name            = azurerm_resource_group.rg.name
#   loadbalancer_id                = azurerm_lb.lb.id
#   protocol                       = "Tcp"
#   frontend_port                  = 60007
#   backend_port                   = 22
#   frontend_ip_configuration_name = "FrontEnd"
# }

# resource "azurerm_network_interface_nat_rule_association" "vpb3_nat" {
#   network_interface_id  = azurerm_network_interface.vpb3_nic1.id
#   ip_configuration_name = "ipconfig1"
#   nat_rule_id           = azurerm_lb_nat_rule.ssh_vpb3.id
# }

# # ILB Backend Pool Associations for VPB3
# resource "azurerm_network_interface_backend_address_pool_association" "vpb3_ingress_pool" {
#   network_interface_id    = azurerm_network_interface.vpb3_nic2.id
#   ip_configuration_name   = "ipconfig1"
#   backend_address_pool_id = azurerm_lb_backend_address_pool.ilb_backend_pool.id
# }
# output "vpb3_public_ip" {
#   value = azurerm_public_ip.vpb3_public_ip.ip_address
# }

#Direct SSH to VPB3: ssh vpb@${azurerm_public_ip.vpb3_public_ip.ip_address}
#SSH to VPB3 via Load Balancer: ssh vpb@${azurerm_public_ip.lb_public_ip.ip_address} -p 60007

# Outputs
output "vpb2_public_ip" {
  value = azurerm_public_ip.vpb2_public_ip.ip_address
}

output "vpb_ingress_ilb_ip" {
  value = azurerm_lb.ilb.frontend_ip_configuration[0].private_ip_address
}

output "ntop_tool1_public_ip" {
  value = azurerm_public_ip.ntop_tool1_public_ip.ip_address
}

output "ntop_tool2_public_ip" {
  value = azurerm_public_ip.ntop_tool2_public_ip.ip_address
}

output "vpb_public_ip" {
  value = azurerm_public_ip.vpb_public_ip.ip_address
}

output "load_balancer_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

# Update SSH instructions
output "ssh_instructions" {
  value = <<EOF
SSH to ntop_tool1 via Load Balancer: ssh azureuser@${azurerm_public_ip.lb_public_ip.ip_address} -p 60004
SSH to ntop_tool2 via Load Balancer: ssh azureuser@${azurerm_public_ip.lb_public_ip.ip_address} -p 60005
SSH to WebServer1 source NIC: ssh azureuser@${azurerm_public_ip.lb_public_ip.ip_address} -p 60001
SSH to VPB2 via Load Balancer: ssh vpb@${azurerm_public_ip.lb_public_ip.ip_address} -p 60006


Direct SSH to ntop_tool2 VM: ssh azureuser@${azurerm_public_ip.ntop_tool2_public_ip.ip_address}
Direct SSH to VPB1: ssh vpb@${azurerm_public_ip.vpb_public_ip.ip_address}
Direct SSH to VPB2: ssh vpb@${azurerm_public_ip.vpb2_public_ip.ip_address}
EOF
}
