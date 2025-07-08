# modules/security/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "target_tags" {
  description = "Target tags for firewall rules"
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
  description = "Internal IP ranges"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "custom_firewall_rules" {
  description = "Custom firewall rules"
  type = map(object({
    description   = string
    direction     = string
    priority      = number
    source_ranges = optional(list(string))
    source_tags   = optional(list(string))
    target_tags   = optional(list(string))
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
  }))
  default = {}
}