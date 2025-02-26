# Network Security Group for PLB
resource "azurerm_network_security_group" "plb_nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.plb_gwlb_rg.location
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

# NSG Association with Subnet
resource "azurerm_subnet_network_security_group_association" "mgmt_nsg_assoc" {
  subnet_id                 = azurerm_subnet.mgmt_subnet.id
  network_security_group_id = azurerm_network_security_group.plb_nsg.id
}

# Platform Load Balancer (PLB)
resource "azurerm_lb" "plb" {
  name                = var.plb_name
  location            = azurerm_resource_group.plb_gwlb_rg.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.plb_frontend_ip_name
    public_ip_address_id = azurerm_public_ip.plb_public_ip.id
  }
}

# Public IP for PLB (for internet-facing communication)
resource "azurerm_public_ip" "plb_public_ip" {
  name                = var.plb_public_ip_name
  location            = azurerm_resource_group.plb_gwlb_rg.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Health Probe for PLB
resource "azurerm_lb_probe" "plb_health_probe" {
  loadbalancer_id     = azurerm_lb.plb.id
  name                = var.plb_probe_name
  protocol            = var.plb_probe_protocol
  port                = var.plb_probe_port
  interval_in_seconds = var.plb_probe_interval
  number_of_probes    = var.plb_probe_count
}

# Backend Pool for PLB
resource "azurerm_lb_backend_address_pool" "plb_backend_pool" {
  name            = var.plb_backend_pool_name
  loadbalancer_id = azurerm_lb.plb.id
}

# Load Balancer Rule for traffic forwarding (PLB to GWLB)
resource "azurerm_lb_rule" "plb_rule" {
  loadbalancer_id                = azurerm_lb.plb.id
  name                           = var.plb_lb_rule_name
  protocol                       = var.plb_rule_protocol
  frontend_port                  = var.plb_rule_frontend_port
  backend_port                   = var.plb_rule_backend_port
  frontend_ip_configuration_name = azurerm_lb.plb.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.plb_health_probe.id
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.plb_backend_pool.id]
}
