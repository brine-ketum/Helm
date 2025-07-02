# environments/prod/variables.tf

# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-east1"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "brinek"
}

# VM Counts
variable "ubuntu_vm_count" {
  description = "Number of Ubuntu VMs to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.ubuntu_vm_count >= 0
    error_message = "Ubuntu VM count must be 0 or greater."
  }
}

variable "rhel_vm_count" {
  description = "Number of RHEL VMs to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.rhel_vm_count >= 0
    error_message = "RHEL VM count must be 0 or greater."
  }
}

variable "windows_vm_count" {
  description = "Number of Windows VMs to create"
  type        = number
  default     = 0
  
  validation {
    condition     = var.windows_vm_count >= 0
    error_message = "Windows VM count must be 0 or greater."
  }
}

# SSH Configuration
variable "ssh_username" {
  description = "SSH username for Linux instances"
  type        = string
  default     = "brinendamketum"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key file (for output instructions)"
  type        = string
}

# Network Configuration
variable "allowed_ssh_ips" {
  description = "List of IPs allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "allowed_rdp_ips" {
  description = "List of IPs allowed for RDP access"
  type        = list(string)
  default     = []
}

variable "allowed_winrm_ips" {
  description = "List of IPs allowed for WinRM access"
  type        = list(string)
  default     = []
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs"
  type        = bool
  default     = false
}

# Windows Configuration
variable "windows_admin_username" {
  description = "Admin username for Windows instances"
  type        = string
  default     = "brine"
  sensitive   = true
}

variable "windows_admin_password" {
  description = "Admin password for Windows instances"
  type        = string
  default     = "Bravedemo123."
  sensitive   = true
}

# Tags and Labels
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = list(string)
  default     = []
}

variable "additional_labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}