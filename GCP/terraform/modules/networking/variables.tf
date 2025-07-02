# modules/networking/variables.tf

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_description" {
  description = "Description of the VPC"
  type        = string
  default     = ""
}

variable "routing_mode" {
  description = "The network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"
  
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be either REGIONAL or GLOBAL."
  }
}

variable "mtu" {
  description = "The network MTU. Must be a value between 1460 and 1500 inclusive"
  type        = number
  default     = 1460
  
  validation {
    condition     = var.mtu >= 1460 && var.mtu <= 1500
    error_message = "MTU must be between 1460 and 1500 inclusive."
  }
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    ip_cidr_range            = string
    region                   = string
    description              = optional(string)
    private_ip_google_access = optional(bool, true)
    enable_flow_logs         = optional(bool, false)
    flow_logs_interval       = optional(string, "INTERVAL_10_MIN")
    flow_logs_sampling       = optional(number, 0.5)
    flow_logs_metadata       = optional(string, "INCLUDE_ALL_METADATA")
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway for the VPC"
  type        = bool
  default     = false
}

variable "nat_region" {
  description = "Region for the NAT gateway"
  type        = string
  default     = ""
}

variable "enable_private_service_connect" {
  description = "Whether to enable Private Service Connect for Google APIs"
  type        = bool
  default     = false
}