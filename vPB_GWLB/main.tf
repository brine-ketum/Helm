provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Resource Group for PLB, GWLB, vPacketStack, and Monitoring Tools
resource "azurerm_resource_group" "plb_gwlb_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "plb_gwlb_vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.plb_gwlb_rg.location
  resource_group_name = azurerm_resource_group.plb_gwlb_rg.name
}

# Subnet for Management, Traffic, and Tools
resource "azurerm_subnet" "mgmt_subnet" {
  name                 = var.mgmt_subnet_name
  resource_group_name  = azurerm_resource_group.plb_gwlb_rg.name
  virtual_network_name = azurerm_virtual_network.plb_gwlb_vnet.name
  address_prefixes     = var.mgmt_subnet_prefix
}

resource "azurerm_subnet" "traffic_subnet" {
  name                 = var.traffic_subnet_name
  resource_group_name  = azurerm_resource_group.plb_gwlb_rg.name
  virtual_network_name = azurerm_virtual_network.plb_gwlb_vnet.name
  address_prefixes     = var.traffic_subnet_prefix
}

resource "azurerm_subnet" "tools_subnet" {
  name                 = var.tools_subnet_name
  resource_group_name  = azurerm_resource_group.plb_gwlb_rg.name
  virtual_network_name = azurerm_virtual_network.plb_gwlb_vnet.name
  address_prefixes     = var.tools_subnet_prefix
}

