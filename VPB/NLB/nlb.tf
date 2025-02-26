# Declare the prefix variable
variable "prefix" {
  type        = string
  description = "Prefix for naming resources"
  default     = "demo"  # You can change this prefix as needed
}

# Configure the Azure provider
provider "azurerm" {
  features {}  # This is a required argument for the azurerm provider
  subscription_id = "15aa2ef1-8214-4cab-9974-d05715c7e9e8"
}

# Reference the existing resource group
data "azurerm_resource_group" "existing" {
  name = "avsRG"
}

# Reference the existing virtual network
data "azurerm_virtual_network" "existing_vnet" {
  name                = "vnet-Tool"
  resource_group_name = data.azurerm_resource_group.existing.name
}

# Reference the existing subnet inside the virtual network
data "azurerm_subnet" "existing_subnet" {
  name                 = "default"  # Replace with your actual subnet name
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = data.azurerm_resource_group.existing.name
}

# Create a Load Balancer with a private IP address
resource "azurerm_lb" "network_lb" {
  name                = "${var.prefix}-network-lb"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  sku                 = "Basic"  # Can also be "Standard" if needed

  frontend_ip_configuration {
    name                       = "${var.prefix}-frontend-ip"
    subnet_id                  = data.azurerm_subnet.existing_subnet.id  # Assign subnet for private IP
    private_ip_address          = "10.2.0.100"  
    private_ip_address_allocation = "Static"     
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "lb_backend" {
  name            = "${var.prefix}-backend-pool"
  loadbalancer_id = azurerm_lb.network_lb.id
}

# Health Probe (for checking vPB health)
resource "azurerm_lb_probe" "http_probe" {
  name            = "${var.prefix}-http-probe"
  loadbalancer_id = azurerm_lb.network_lb.id
  protocol        = "Tcp"
  port            = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancer Rule for HTTP Traffic
resource "azurerm_lb_rule" "http_lb_rule" {
  name                            = "${var.prefix}-http-lb-rule"
  loadbalancer_id                 = azurerm_lb.network_lb.id
  protocol                        = "Tcp"
  frontend_port                   = 80
  backend_port                    = 80
  frontend_ip_configuration_name  = "${var.prefix}-frontend-ip"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.lb_backend.id]  
  probe_id                        = azurerm_lb_probe.http_probe.id
}

# Reference existing network interfaces for the vPB
data "azurerm_network_interface" "auto_vpb_nic_main" {
  name                = "demo-vpb-nic-main"  
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_network_interface" "auto_vpb_nic_eth1" {
  name                = "demo-vpb-nic-eth1"  
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_network_interface" "auto_vpb_nic_eth2" {
  name                = "demo-vpb-nic-eth2" 
  resource_group_name = data.azurerm_resource_group.existing.name
}

# Associate the main interface of vPB with the load balancer's backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vpb_nic_lb_association_main" {
  network_interface_id            = data.azurerm_network_interface.auto_vpb_nic_main.id  
  ip_configuration_name           = "${var.prefix}-vpb-nic-main-config"  
  backend_address_pool_id         = azurerm_lb_backend_address_pool.lb_backend.id
}

# Associate the eth1 interface of vPB with the load balancer's backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vpb_nic_lb_association_eth1" {
  network_interface_id            = data.azurerm_network_interface.auto_vpb_nic_eth1.id  
  ip_configuration_name           = "${var.prefix}-vpb-nic-eth1-config"  
  backend_address_pool_id         = azurerm_lb_backend_address_pool.lb_backend.id
}

# Associate the eth2 interface of vPB with the load balancer's backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vpb_nic_lb_association_eth2" {
  network_interface_id            = data.azurerm_network_interface.auto_vpb_nic_eth2.id  
  ip_configuration_name           = "${var.prefix}-vpb-nic-eth2-config"  
  backend_address_pool_id         = azurerm_lb_backend_address_pool.lb_backend.id
}

# Output for the private IP of the Load Balancer
output "lb_private_ip" {
  value = azurerm_lb.network_lb.frontend_ip_configuration[0].private_ip_address
}
