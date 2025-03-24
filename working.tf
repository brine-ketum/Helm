# Azure Provider configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0, <5.0" # Ensure you're using a stable version
    }
  }
  required_version = ">=1.9.5"
}

provider "azurerm" {
  features {}

   subscription_id = "16e5b426-6372-4975-908a-e4cc44ee3cab" 
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "CloudLensGwLB-rg"
  location = "eastus2" 
}


# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "VNet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnets
resource "azurerm_subnet" "consumer_subnet" {
  name                 = "ConsumerBackendNet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "provider_subnet" {
  name                 = "ProviderBackendNet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "management_subnet" {
  name                 = "CLManagementNet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_subnet" "tool_subnet" {
  name                 = "CLToolNet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.3.0/24"]
}

# Create public IP for load balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# # Create separate Public IP for Gateway Load Balancer
# resource "azurerm_public_ip" "gwlb_public_ip" {
#   name                = "GWLB-PublicIP"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["1", "2", "3"]
# }

# Standard Load Balancer (Fix: Use only one frontend IP)
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

# Create backend pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "GWLBBackendPool"
}

#added

resource "azurerm_route_table" "web_route_table" {
  name                = "WebRouteTable"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

data "azurerm_lb" "gwlb" {
  name                = azurerm_lb.gw_lb.name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_lb.gw_lb]
}

# Create health probe
resource "azurerm_lb_probe" "health_probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "HealthProbe"
  port            = 80
  protocol        = "Tcp"
}

#added
resource "azurerm_network_interface_backend_address_pool_association" "gwlb_pool_association" {
  network_interface_id    = azurerm_network_interface.vpb_nic2.id  # VPB NIC
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

}

resource "azurerm_route" "vpb_to_web_servers" {
  name                = "VPBToWebServers"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.vpb_route_table.name

  address_prefix      = "10.1.0.0/24" # Consumer Subnet
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.vpb_nic2.private_ip_address

  depends_on = [azurerm_route_table.vpb_route_table]
}

resource "azurerm_subnet_route_table_association" "consumer_subnet_route" {
  subnet_id      = azurerm_subnet.consumer_subnet.id
  route_table_id = azurerm_route_table.vpb_route_table.id
}

resource "azurerm_lb_rule" "lb_to_gwlb" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBToGWLB"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "FrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.health_probe.id
}

# Create NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_vxlan" {
  name                        = "AllowVXLAN"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_ranges      = ["10801", "10802"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Create NSG rule for HTTP
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

# Create NSG rule for SSH
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

# Create NAT Gateway Public IP
resource "azurerm_public_ip" "nat_gateway_ip" {
  name                = "NATgatewayIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# Create NAT Gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = "NATgateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  idle_timeout_in_minutes = 10
}

# Associate public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

# Associate NAT Gateway with subnet
resource "azurerm_subnet_nat_gateway_association" "nat_subnet_association" {
  subnet_id      = azurerm_subnet.consumer_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id

  depends_on = [azurerm_nat_gateway_public_ip_association.nat_ip_association]
}

locals {
  cloud_init_webserver = templatefile("${path.module}/cloud_init_webserver.tpl", {})
}

# Create network interfaces for VMs
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

# Associate NSG with NICs
resource "azurerm_network_interface_security_group_association" "nic_vm1_nsg" {
  network_interface_id      = azurerm_network_interface.nic_vm1.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [azurerm_network_interface.nic_vm1]
}

resource "azurerm_network_interface_security_group_association" "nic_vm2_nsg" {
  network_interface_id      = azurerm_network_interface.nic_vm2.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [azurerm_network_interface.nic_vm2]
}

# Create Web VMs
resource "azurerm_linux_virtual_machine" "web_server1" {
  name                = "WebServer1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Keysight123456"
  zone                = "1"
  disable_password_authentication = false
  custom_data = base64encode(local.cloud_init_webserver)

  network_interface_ids = [
    azurerm_network_interface.nic_vm1.id,
  ]

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

resource "azurerm_linux_virtual_machine" "web_server2" {
  name                = "WebServer2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Keysight123456"
  zone                = "1"
  disable_password_authentication = false
  custom_data         = base64encode(local.cloud_init_webserver)

  network_interface_ids = [
    azurerm_network_interface.nic_vm2.id,
  ]

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

# Create NAT rules for SSH access to web servers
resource "azurerm_lb_nat_rule" "ssh_vm1" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "SSHWebServer1"
  protocol                       = "Tcp"
  frontend_port                  = 60001
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

resource "azurerm_lb_nat_rule" "ssh_vm2" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "SSHWebServer2"
  protocol                       = "Tcp"
  frontend_port                  = 60002
  backend_port                   = 22
  frontend_ip_configuration_name = "FrontEnd"
}

# Associate NAT rules with NICs
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

# Associate NICs with LB backend pool
resource "azurerm_network_interface_backend_address_pool_association" "nic_vm1_lb_pool" {
  network_interface_id    = azurerm_network_interface.nic_vm1.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

  depends_on = [azurerm_lb_backend_address_pool.backend_pool]
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_vm2_lb_pool" {
  network_interface_id    = azurerm_network_interface.nic_vm2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

  depends_on = [azurerm_lb_backend_address_pool.backend_pool]
}

# Gateway Load Balancer (Fix: Use separate Public IP)
resource "azurerm_lb" "gw_lb" {
  name                = "GWLoadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Gateway"

  frontend_ip_configuration {
    name              =  "FrontEnd"
    subnet_id         =   azurerm_subnet.provider_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_route" "vpb_to_gwlb" {
  name                = "VPBToGWLB"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.vpb_route_table.name
  address_prefix      = azurerm_subnet.provider_subnet.address_prefixes[0]  # Route all traffic in provider subnet
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = data.azurerm_lb.gwlb.frontend_ip_configuration[0].private_ip_address # Dynamically fetch GWLB IP

  depends_on = [
    azurerm_lb.gw_lb,   # Ensure GWLB is fully created before adding this route
    azurerm_route_table.vpb_route_table  # Ensure route table exists before adding routes
  ]
}

# Backend Pool for Gateway Load Balancer 
resource "azurerm_lb_backend_address_pool" "gw_backend_pool" {
  loadbalancer_id = azurerm_lb.gw_lb.id
  name            = "BackendPool"

  tunnel_interface {
    identifier = 901
    type       = "External"
    protocol   = "VXLAN"
    port       = 10801
  }

  tunnel_interface {  
    identifier = 902
    type       = "Internal"
    protocol   = "VXLAN"
    port       = 10802
  }
}

# Allow inbound and Outbound VXLAN for vPB
resource "azurerm_network_security_rule" "vpb_allow_vxlann" {
  name                        = "AllowVXLANPorts"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_ranges     = ["10801", "10802"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vpb_nsg.name
}
resource "azurerm_network_security_rule" "vpb_allow_vxlan" {
  name                        = "AllowVXLANOutbound"
  priority                    = 140
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_ranges     = ["10801", "10802"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

#added
resource "azurerm_network_security_rule" "http_web" {

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


resource "azurerm_route" "web_subnet_to_vpb" {
  name                = "RouteToVPB"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.web_route_table.name

  address_prefix        = "10.1.0.0/24"  # Consumer subnet where web servers reside
  next_hop_type         = "VirtualAppliance"
  next_hop_in_ip_address = "10.1.1.4"  # VPB's Private IP in Provider Subnet
}

# Create health probe for Gateway Load Balancer
resource "azurerm_lb_probe" "gw_health_probe" {
  loadbalancer_id = azurerm_lb.gw_lb.id
  name            = "HealthProbe"
  port            = 80
  protocol        = "Tcp"
  interval_in_seconds = 5
}

# Create load balancer rule for Gateway LB
resource "azurerm_lb_rule" "gw_lb_rule" {
  loadbalancer_id                = azurerm_lb.gw_lb.id
  name                           = "LBRule"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "FrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.gw_backend_pool.id]
  probe_id                       = azurerm_lb_probe.gw_health_probe.id
}

resource "azurerm_route" "provider_subnet_to_gwlb" {
  name                = "RouteToGatewayLB"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.vpb_route_table.name # The VPB route table

  address_prefix      = "0.0.0.0/0"                             # Forward all traffic
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = data.azurerm_lb.gwlb.frontend_ip_configuration[0].private_ip_address 

  depends_on = [azurerm_lb.gw_lb, azurerm_route_table.vpb_route_table, data.azurerm_lb.gwlb]
}

# Create Tool VM
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
    subnet_id                     = azurerm_subnet.tool_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tool_vm_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "tool_vm_nsg" {
  network_interface_id      = azurerm_network_interface.tool_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Add a specific outbound rule for the SSH connection to function properly

resource "azurerm_network_security_rule" "tool_vm_outbound" {
  name                        = "AllowOutboundFromToolVM"
  priority                    = 202
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

resource "azurerm_linux_virtual_machine" "tool_vm" {
  name                = "ToolVM"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Keysight123456"
  zone                = "1"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.tool_nic.id,
  ]

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

  # Add cloud-init script to install net-tools & tcpdump
  custom_data = base64encode(<<EOF
#!/bin/bash
apt update -y
apt install -y net-tools tcpdump
EOF
  )
}


# Create NSG for VPB
resource "azurerm_network_security_group" "vpb_nsg" {
  name                = "vPB-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create NSG rules for VPB
resource "azurerm_network_security_rule" "vpb_allow_all_in" {
  name                        = "myNSGRule-AllowAll"
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
  name                        = "myNSGRule-AllowAll-TCP-Out"
  priority                    = 100
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

resource "azurerm_route_table" "vpb_route_table" {
  name                = "VPBRouteTable"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_route" "vxlan_route" {
  name                = "VXLANRoute"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.vpb_route_table.name
  address_prefix      = "10.1.1.4/32"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = "10.1.1.5"
}

resource "azurerm_subnet_route_table_association" "provider_subnet_route" {
  subnet_id      = azurerm_subnet.provider_subnet.id
  route_table_id = azurerm_route_table.vpb_route_table.id
}

# Create public IP for VPB
resource "azurerm_public_ip" "vpb_public_ip" {
  name                = "vPB-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# Create NICs for VPB
resource "azurerm_network_interface" "vpb_nic1" {
  name                = "vPBNic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.management_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpb_public_ip.id
  }
}

resource "azurerm_network_interface" "vpb_nic2" {
  name                          = "vPBNic2"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
 
  # enable_accelerated_networking = true  # Ensure accelerated networking is enabled

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.provider_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "vpb_nic3" {
  name                          = "vPBNic3"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name


  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tool_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NICs
resource "azurerm_network_interface_security_group_association" "vpb_nic1_nsg" {
  network_interface_id      = azurerm_network_interface.vpb_nic1.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
  depends_on = [azurerm_network_interface.vpb_nic1, azurerm_network_security_group.vpb_nsg]
}

resource "azurerm_network_interface_security_group_association" "vpb_nic2_nsg" {
  network_interface_id      = azurerm_network_interface.vpb_nic2.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
  depends_on = [azurerm_network_interface.vpb_nic2, azurerm_network_security_group.vpb_nsg]
}

resource "azurerm_network_interface_security_group_association" "vpb_nic3_nsg" {
  network_interface_id      = azurerm_network_interface.vpb_nic3.id
  network_security_group_id = azurerm_network_security_group.vpb_nsg.id
  depends_on = [azurerm_network_interface.vpb_nic3, azurerm_network_security_group.vpb_nsg]
}

# Fix: Use Valid Ubuntu Image in VPB VM
resource "azurerm_linux_virtual_machine" "vpb_vm" {
  name                = "vPB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D8_v5"
  admin_username      = "vpb"
  admin_password      = "Keysight!123456"
  zone                = "1"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vpb_nic1.id,
    azurerm_network_interface.vpb_nic2.id,
    azurerm_network_interface.vpb_nic3.id,
  ]

  depends_on = [
    azurerm_network_interface.vpb_nic1,
    azurerm_network_interface.vpb_nic2,
    azurerm_network_interface.vpb_nic3,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"  # Fix: Valid Ubuntu image SKU
    version   = "latest"
  }
}

# Script to install VPB
resource "null_resource" "vpb_install" {

  depends_on = [azurerm_linux_virtual_machine.vpb_vm]

  triggers = {
    force_reapply = timestamp() # Forces execution on every apply
  }

  provisioner "local-exec" {
    command = "sleep 120"
  }

  provisioner "file" {
    source      = "/Users/brinketu/Downloads/vpb-3.9.0-42-install-package.sh" 
    destination = "/home/vpb/vpb-installer.sh"

    connection {
      type     = "ssh"
      user     = "vpb"
      password = "Keysight!123456"
      timeout  = "10m"
      host     = azurerm_public_ip.vpb_public_ip.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "ls -l /home/vpb",                      # Debugging step: List files to confirm upload
      "sleep 10",                             # Wait for file to be fully copied
      "chmod +x /home/vpb/vpb-installer.sh",   # Ensure execute permissions
      "sudo bash /home/vpb/vpb-installer.sh"   # Explicitly run with bash
    ]

    connection {
      type     = "ssh"
      user     = "vpb"
      password = "Keysight!123456"
      timeout  = "45m"
      host     = azurerm_public_ip.vpb_public_ip.ip_address
    }
  }
}

# Add VPB to Gateway Load Balancer backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vpb_nic2_gwlb_pool" {
  network_interface_id    = azurerm_network_interface.vpb_nic2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.gw_backend_pool.id
  depends_on              = [azurerm_lb_backend_address_pool.gw_backend_pool, azurerm_network_interface.vpb_nic2]

}



# Output Fix: Show Correct IPs
output "load_balancer_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

# output "gwlb_public_ip" {  
#   value = azurerm_public_ip.gwlb_public_ip.ip_address
# }

output "tool_vm_public_ip" {
  value = azurerm_public_ip.tool_vm_public_ip.ip_address
}

output "vpb_public_ip" {
  value = azurerm_public_ip.vpb_public_ip.ip_address
}
output "gwlb_ip" {
  value = data.azurerm_lb.gwlb.frontend_ip_configuration[0].private_ip_address
}

output "ssh_instructions" {
  value = <<EOF
# SSH Instructions for all tools:

# Web Servers:
SSH to WebServer1: ssh azureuser@${azurerm_public_ip.lb_public_ip.ip_address} -p 60001
SSH to WebServer2: ssh azureuser@${azurerm_public_ip.lb_public_ip.ip_address} -p 60002

# Virtual Packet Broker (VPB):
SSH to vPB VM: ssh vpb@${azurerm_public_ip.vpb_public_ip.ip_address}

# Tool VMs:
SSH to Tool VM: ssh azureuser@${azurerm_public_ip.tool_vm_public_ip.ip_address}

# Gateway Load Balancer (GWLB) (Private Access Only):
GWLB Private IP: ${data.azurerm_lb.gwlb.frontend_ip_configuration[0].private_ip_address}
EOF
}


#ALway Rem to tun on accelrated networking and backend pool admin state to up fro gwlb and vpb
# Enable ip forwarding for Nic 2 and 3

