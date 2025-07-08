# modules/security/variables.tf

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
}

variable "network_name" {
  description = "The name of the network for naming resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with the NSG"
  type        = list(string)
  default     = []
}

variable "ssh_source_addresses" {
  description = "Source IP addresses allowed for SSH"
  type        = list(string)
  default     = []
}

variable "rdp_source_addresses" {
  description = "Source IP addresses allowed for RDP"
  type        = list(string)
  default     = []
}

variable "internal_ranges" {
  description = "Internal IP ranges for unrestricted communication"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "create_default_rules" {
  description = "Create default security rules"
  type        = bool
  default     = true
}

variable "custom_security_rules" {
  description = "Custom security rules"
  type = map(object({
    description                  = optional(string)
    direction                    = string
    priority                     = number
    access                       = string
    protocol                     = string
    source_port_range           = optional(string)
    destination_port_range      = optional(string)
    destination_port_ranges     = optional(list(string))
    source_address_prefix       = optional(string)
    source_address_prefixes     = optional(list(string))
    destination_address_prefix  = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
  default = {}
}

variable "application_security_groups" {
  description = "Application security groups to create"
  type = map(object({
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}