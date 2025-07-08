# environments/prod/variables.tf

# Azure Configuration
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "westus2"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "brinek"
}

# Service Principal Configuration
variable "service_principal_client_id" {
  description = "Client ID of the service principal for OpenShift"
  type        = string
  sensitive   = true
}

variable "service_principal_client_secret" {
  description = "Client Secret of the service principal for OpenShift"
  type        = string
  sensitive   = true
}

variable "service_principal_object_id" {
  description = "Object ID of the service principal for OpenShift"
  type        = string
  sensitive   = true
}

# OpenShift Configuration
variable "openshift_version" {
  description = "OpenShift version"
  type        = string
  default     = "4.13.23"  # Check for latest stable version
}

variable "openshift_domain" {
  description = "Custom domain for OpenShift cluster (optional)"
  type        = string
  default     = ""
}

variable "openshift_pull_secret" {
  description = "Red Hat pull secret for OpenShift"
  type        = string
  sensitive   = true
}

# Master Node Configuration
variable "master_vm_size" {
  description = "VM size for master nodes"
  type        = string
  default     = "Standard_D8s_v3"
}

variable "master_vm_disk_size_gb" {
  description = "OS disk size for master nodes"
  type        = number
  default     = 128
}

# Worker Node Configuration
variable "worker_vm_size" {
  description = "VM size for worker nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "worker_vm_disk_size_gb" {
  description = "OS disk size for worker nodes"
  type        = number
  default     = 128
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
  
  validation {
    condition     = var.worker_node_count >= 3 && var.worker_node_count <= 60
    error_message = "Worker node count must be between 3 and 60 for Azure Red Hat OpenShift."
  }
}

# Additional Worker Profiles
variable "additional_worker_profiles" {
  description = "Additional worker node profiles"
  type = map(object({
    vm_size         = string
    vm_disk_size_gb = number
    node_count      = number
  }))
  default = {}
}

# Network Configuration
variable "api_server_visibility" {
  description = "API server visibility (Public or Private)"
  type        = string
  default     = "Public"
  
  validation {
    condition     = contains(["Public", "Private"], var.api_server_visibility)
    error_message = "API server visibility must be Public or Private."
  }
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_visibility" {
  description = "Ingress visibility (Public or Private)"
  type        = string
  default     = "Public"
  
  validation {
    condition     = contains(["Public", "Private"], var.ingress_visibility)
    error_message = "Ingress visibility must be Public or Private."
  }
}

# DNS Configuration
variable "create_dns_zone" {
  description = "Create Azure DNS zone for custom domain"
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Name of the Azure DNS zone"
  type        = string
  default     = ""
}

# Additional Configuration
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}