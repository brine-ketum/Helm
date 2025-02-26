# Gateway Load Balancer (GWLB)
resource "azurerm_lb" "gwlb" {
  name                = var.gwlb_name
  location            = azurerm_resource_group.plb_gwlb_rg.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name
  sku                 = "Gateway"

  frontend_ip_configuration {
    name                 = var.gwlb_frontend_ip_name
    subnet_id            = azurerm_subnet.traffic_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Health Probe for GWLB
resource "azurerm_lb_probe" "gwlb_health_probe" {
  loadbalancer_id     = azurerm_lb.gwlb.id
  name                = var.gwlb_probe_name
  protocol            = var.gwlb_probe_protocol
  port                = var.gwlb_probe_port
  interval_in_seconds = var.gwlb_probe_interval
  number_of_probes    = var.gwlb_probe_count
}

# Load Balancer Rule for GWLB traffic forwarding
resource "azurerm_lb_rule" "gwlb_rule" {
  loadbalancer_id                = azurerm_lb.gwlb.id
  name                           = var.gwlb_lb_rule_name
  protocol                       = var.gwlb_rule_protocol
  frontend_port                  = var.gwlb_rule_frontend_port
  backend_port                   = var.gwlb_rule_backend_port
  frontend_ip_configuration_name = azurerm_lb.gwlb.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.gwlb_health_probe.id
}

