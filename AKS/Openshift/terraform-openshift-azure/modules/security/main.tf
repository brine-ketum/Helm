# modules/security/main.tf

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.network_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Default Security Rules only if requested
resource "azurerm_network_security_rule" "ssh" {
  count = var.create_default_rules && length(var.ssh_source_addresses) > 0 ? 1 : 0
  
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.ssh_source_addresses
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Allow internal communication
resource "azurerm_network_security_rule" "internal" {
  count = var.create_default_rules ? 1 : 0
  
  name                        = "allow-internal"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.internal_ranges
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Custom Security Rules
resource "azurerm_network_security_rule" "custom" {
  for_each = var.custom_security_rules
  
  name                         = each.key
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = lookup(each.value, "source_port_range", "*")
  destination_port_ranges      = lookup(each.value, "destination_port_ranges", null)
  destination_port_range       = lookup(each.value, "destination_port_ranges", null) == null ? lookup(each.value, "destination_port_range", "*") : null
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null)
  source_address_prefix        = lookup(each.value, "source_address_prefixes", null) == null ? lookup(each.value, "source_address_prefix", "*") : null
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefixes", null) == null ? lookup(each.value, "destination_address_prefix", "*") : null
  description                  = lookup(each.value, "description", null)
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.main.name
}

# Note: We don't associate NSG with subnets for OpenShift
# OpenShift manages its own network security

# Application Security Groups (optional)
resource "azurerm_application_security_group" "main" {
  for_each = var.application_security_groups
  
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = merge(var.tags, each.value.tags)
}