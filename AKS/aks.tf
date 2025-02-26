## Provider Configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # Use the latest 3.x version
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "16e5b426-6372-4975-908a-e4cc44ee3cab"
}

## Variables
variable "location" {
  description = "Azure region where resources will be created"
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "aksResourceGroup"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  default     = "Keysight_AZ_Cluster"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  default     = "brinesregistry"
}

variable "node_count" {
  description = "Number of nodes in the AKS cluster"
  default     = 3
}

## Resource Group
resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location
}

## Virtual Network
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aksVnet"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

## Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aksSubnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.240.0.0/16"]
}

## Create Public IP Prefix
resource "azurerm_public_ip_prefix" "nat_prefix" {
  name                = "pipp-nat-gateway"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  prefix_length       = 29
  sku                 = "Standard"
}

## Create NAT Gateway
resource "azurerm_nat_gateway" "gw_aks" {
  name                = "natgw-aks"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku_name            = "Standard"
}

## Associate NAT Gateway with Public IP Prefix
resource "azurerm_nat_gateway_public_ip_prefix_association" "nat_ips" {
  nat_gateway_id      = azurerm_nat_gateway.gw_aks.id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat_prefix.id
}

## Attach the NAT Gateway to the Subnet
resource "azurerm_subnet_nat_gateway_association" "sn_cluster_nat_gw" {
  subnet_id      = azurerm_subnet.aks_subnet.id
  nat_gateway_id = azurerm_nat_gateway.gw_aks.id
}

## Create a Network Security Group (NSG) for AKS
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aksNSG"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

## Allow all inbound traffic
resource "azurerm_network_security_rule" "allow_all_inbound" {
  name                        = "AllowAllInbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.aks_rg.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
}

## Allow all outbound traffic
resource "azurerm_network_security_rule" "allow_all_outbound" {
  name                        = "AllowAllOutbound"
  priority                    = 1001
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.aks_rg.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
}

## Attach the NSG to the AKS Subnet
resource "azurerm_subnet_network_security_group_association" "aks_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

## Azure Kubernetes Service (AKS) Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aksdns"

  default_node_pool {
    name           = "node"
    node_count     = var.node_count
    vm_size        = "Standard_DS3_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    dns_service_ip = "10.0.0.10"
    service_cidr   = "10.0.0.0/16"
    outbound_type  = "userAssignedNATGateway"
  }

  tags = {
    Environment = "demo"
  }

  depends_on = [
    azurerm_subnet_nat_gateway_association.sn_cluster_nat_gw
  ]
}

## Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

## Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id

  depends_on = [
    azurerm_container_registry.acr,
    azurerm_kubernetes_cluster.aks
  ]
}

## Output the AKS and ACR details
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "acr_login_server" {
  description = "The login server of the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}
