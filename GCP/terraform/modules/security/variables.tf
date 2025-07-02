# modules/security/variables.tf

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "enable_default_rules" {
  description = "Whether to create default firewall rules"
  type        = bool
  default     = true
}

variable "target_tags" {
  description = "Default target tags for firewall rules"
  type        = list(string)
  default     = []
}

variable "ssh_source_ranges" {
  description = "Source IP ranges for SSH access"
  type        = list(string)
  default     = []
}

variable "rdp_source_ranges" {
  description = "Source IP ranges for RDP access"
  type        = list(string)
  default     = []
}

variable "winrm_source_ranges" {
  description = "Source IP ranges for WinRM access"
  type        = list(string)
  default     = []
}

variable "internal_ranges" {
  description = "Internal IP ranges for VPC"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "custom_firewall_rules" {
  description = "Map of custom firewall rules"
  type = map(object({
    description    = string
    direction      = string
    priority       = optional(number, 1000)
    source_ranges  = optional(list(string), [])
    destination_ranges = optional(list(string), [])
    source_tags    = optional(list(string), [])
    target_tags    = optional(list(string), [])
    source_service_accounts = optional(list(string), [])
    target_service_accounts = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    enable_logging    = optional(bool, false)
    logging_metadata  = optional(string, "INCLUDE_ALL_METADATA")
    disabled         = optional(bool, false)
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for rule in var.custom_firewall_rules : 
      contains(["INGRESS", "EGRESS"], rule.direction)
    ])
    error_message = "Firewall rule direction must be either INGRESS or EGRESS."
  }
}