# modules/networking/main.tf

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Subnets with OpenShift-specific configurations
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets
  
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  
  # Service endpoints for OpenShift
  service_endpoints = lookup(each.value, "service_endpoints", [
    "Microsoft.Storage",
    "Microsoft.ContainerRegistry"
  ])
  
  # Enable private endpoints for OpenShift
 # Updated syntax for private endpoint policies
  private_endpoint_network_policies = lookup(each.value, "private_endpoint_network_policies_enabled", true) ? "Enabled" : "Disabled"
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)
  
  dynamic "delegation" {
    for_each = lookup(each.value, "delegations", [])
    content {
      name = delegation.value.name
      
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# NAT Gateway Public IP
resource "azurerm_public_ip" "nat" {
  count = var.create_nat_gateway ? 1 : 0
  
  name                = "${var.vnet_name}-nat-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = var.tags
}

# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  count = var.create_nat_gateway ? 1 : 0
  
  name                    = "${var.vnet_name}-nat"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  
  tags = var.tags
}

# Associate NAT Gateway with Public IP
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.create_nat_gateway ? 1 : 0
  
  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

# Associate NAT Gateway with Subnets
resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = var.create_nat_gateway ? { for k, v in var.subnets : k => v if lookup(v, "associate_nat_gateway", true) } : {}
  
  subnet_id      = azurerm_subnet.subnets[each.key].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}
