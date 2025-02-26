variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed"
}

variable "vnet_name" {
  type        = string
  description = "The name of the virtual network"
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the subnet"
}

variable "public_ips" {
  type = map(string)
  description = "Map of names for the public IPs"
}

variable "nsg_name" {
  type        = string
  description = "The name of the Network Security Group"
}

variable "vm_settings" {
  type = map(object({
    os_type         = string
    vm_size         = string
    os_disk_size_gb = number
    publisher       = string
    offer           = string
    sku             = string
  }))
  description = "VM settings for various VMs"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the virtual machines"
  sensitive   = true
}

variable "admin_password" {
  type        = string
  description = "Admin password for the virtual machines"
  sensitive   = true
}


