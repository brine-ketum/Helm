# modules/registry/variables.tf

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location where the registry will be created"
  type        = string
}

variable "registry_name" {
  description = "The name of the Container Registry (must be globally unique)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.registry_name))
    error_message = "Registry name must only contain alphanumeric characters."
  }
}

variable "sku" {
  description = "The SKU of the Container Registry"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user"
  type        = bool
  default     = false
}

variable "georeplications" {
  description = "Geo-replication locations (Premium SKU only)"
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool, false)
    tags                    = optional(map(string), {})
  }))
  default = []
}

variable "network_rule_set" {
  description = "Network rule set configuration (Premium SKU only)"
  type = object({
    default_action = string
    ip_rules = optional(list(object({
      action   = string
      ip_range = string
    })), [])
    virtual_network_rules = optional(list(object({
      action    = optional(string)
      subnet_id = string
    })), [])
  })
  default = null
}

variable "retention_policy" {
  description = "Retention policy configuration (Premium SKU only)"
  type = object({
    days    = number
    enabled = bool
  })
  default = null
}

variable "trust_policy_enabled" {
  description = "Enable content trust policy (Premium SKU only)"
  type        = bool
  default     = false
}

variable "encryption" {
  description = "Encryption configuration (Premium SKU only)"
  type = object({
    key_vault_key_id   = string
    identity_client_id = string
  })
  default = null
}

variable "webhooks" {
  description = "Webhooks configuration"
  type = map(object({
    service_uri    = string
    actions        = list(string)
    status         = optional(string)
    scope          = optional(string)
    custom_headers = optional(map(string))
    tags           = optional(map(string))
  }))
  default = {}
}

variable "tasks" {
  description = "Build tasks configuration (Standard and Premium SKUs only)"
  type = map(object({
    platform = object({
      os           = optional(string)
      architecture = optional(string)
      variant      = optional(string)
    })
    dockerfile_path      = string
    context_path         = string
    context_access_token = optional(string)
    image_names          = list(string)
    build_arguments      = optional(map(string))
    secret_arguments     = optional(map(string))
    push_enabled         = optional(bool)
    cache_enabled        = optional(bool)
    source_triggers = optional(list(object({
      name           = string
      events         = list(string)
      source_type    = string
      repository_url = string
      branch         = optional(string)
      authentication = object({
        token      = string
        token_type = string
      })
    })))
    tags = optional(map(string))
  }))
  default = {}
}

variable "scope_maps" {
  description = "Scope maps for token authentication (Premium SKU only)"
  type = map(object({
    actions = list(string)
  }))
  default = {}
}

variable "tokens" {
  description = "Tokens for authentication (Premium SKU only)"
  type = map(object({
    scope_map = string
    enabled   = optional(bool)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to the registry"
  type        = map(string)
  default     = {}
}
