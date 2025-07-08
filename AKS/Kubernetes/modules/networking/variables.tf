# modules/networking/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

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
  description = "VPC routing mode"
  type        = string
  default     = "REGIONAL"
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    ip_cidr_range    = string
    region           = string
    description      = optional(string)
    enable_flow_logs = optional(bool)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })))
  }))
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway"
  type        = bool
  default     = false
}

variable "nat_region" {
  description = "Region for NAT gateway"
  type        = string
  default     = ""
}