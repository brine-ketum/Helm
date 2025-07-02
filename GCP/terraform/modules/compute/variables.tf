# modules/compute/variables.tf

# General Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "zone" {
  description = "The zone where resources will be created"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

# Network Configuration
variable "network" {
  description = "The VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork name"
  type        = string
}

variable "network_tags" {
  description = "Network tags to apply to instances"
  type        = list(string)
  default     = []
}

variable "additional_tags" {
  description = "Additional tags to apply to instances"
  type        = list(string)
  default     = []
}

# Instance Configuration
variable "machine_type" {
  description = "Machine type for instances"
  type        = string
  default     = "n2-standard-2"
}

variable "os_type" {
  description = "Operating system type (linux or windows)"
  type        = string
  default     = "linux"
  
  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "OS type must be either 'linux' or 'windows'."
  }
}

variable "source_image" {
  description = "Source image self-link"
  type        = string
  default     = ""
}

variable "source_image_family" {
  description = "Source image family"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "source_image_project" {
  description = "Project containing the source image"
  type        = string
  default     = "ubuntu-os-cloud"
}

# Boot Disk Configuration
variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
  
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced", "pd-extreme"], var.boot_disk_type)
    error_message = "Boot disk type must be one of: pd-standard, pd-ssd, pd-balanced, pd-extreme."
  }
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_encryption_key" {
  description = "KMS key self-link for disk encryption"
  type        = string
  default     = ""
}

variable "additional_disks" {
  description = "List of additional disks to attach"
  type = list(object({
    disk_size_gb       = number
    disk_type          = optional(string, "pd-standard")
    disk_name          = optional(string)
    device_name        = optional(string)
    mode              = optional(string, "READ_WRITE")
    source            = optional(string)
    source_image      = optional(string)
    type              = optional(string, "PERSISTENT")
    auto_delete       = optional(bool, true)
    disk_encryption_key = optional(string, "")
  }))
  default = []
}

# SSH Configuration (Linux)
variable "ssh_username" {
  description = "SSH username for Linux instances"
  type        = string
  default     = "admin"
}

variable "ssh_public_key" {
  description = "SSH public key for Linux instances"
  type        = string
  default     = ""
}

# Startup Scripts
variable "linux_startup_script" {
  description = "Startup script for Linux instances"
  type        = string
  default     = ""
}

variable "windows_custom_startup_script" {
  description = "Custom startup script for Windows instances"
  type        = string
  default     = ""
}

variable "windows_shutdown_script" {
  description = "Shutdown script for Windows instances"
  type        = string
  default     = ""
}

# Service Account Configuration
variable "create_service_account" {
  description = "Whether to create a service account for instances"
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "Service account email (if not creating one)"
  type        = string
  default     = ""
}

variable "service_account_scopes" {
  description = "Service account scopes"
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append"
  ]
}

variable "service_account_roles" {
  description = "IAM roles to assign to the service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer"
  ]
}

# Network Configuration
variable "enable_public_ip" {
  description = "Whether to assign a public IP"
  type        = bool
  default     = true
}

variable "static_ip" {
  description = "Static IP address to assign"
  type        = string
  default     = ""
}

variable "public_ptr_domain_name" {
  description = "Public PTR domain name"
  type        = string
  default     = ""
}

variable "network_tier" {
  description = "Network tier for the instance"
  type        = string
  default     = "PREMIUM"
  
  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.network_tier)
    error_message = "Network tier must be either PREMIUM or STANDARD."
  }
}

variable "alias_ip_ranges" {
  description = "Alias IP ranges for the instance"
  type = list(object({
    ip_cidr_range         = string
    subnetwork_range_name = optional(string)
  }))
  default = []
}

# Scheduling Configuration
variable "automatic_restart" {
  description = "Whether to automatically restart instance if terminated"
  type        = bool
  default     = true
}

variable "on_host_maintenance" {
  description = "Instance behavior when maintenance occurs"
  type        = string
  default     = "MIGRATE"
  
  validation {
    condition     = contains(["MIGRATE", "TERMINATE"], var.on_host_maintenance)
    error_message = "on_host_maintenance must be either MIGRATE or TERMINATE."
  }
}

variable "preemptible" {
  description = "Whether the instance is preemptible"
  type        = bool
  default     = false
}

variable "spot" {
  description = "Whether to use spot instances"
  type        = bool
  default     = false
}

variable "spot_termination_action" {
  description = "Action to take when spot instance is terminated"
  type        = string
  default     = "STOP"
  
  validation {
    condition     = contains(["STOP", "DELETE"], var.spot_termination_action)
    error_message = "spot_termination_action must be either STOP or DELETE."
  }
}

variable "node_affinities" {
  description = "Node affinities for sole-tenant nodes"
  type = list(object({
    key      = string
    operator = string
    values   = list(string)
  }))
  default = []
}

# Security Configuration
variable "enable_secure_boot" {
  description = "Enable secure boot"
  type        = bool
  default     = false
}

variable "enable_vtpm" {
  description = "Enable vTPM"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring"
  type        = bool
  default     = true
}

variable "enable_confidential_compute" {
  description = "Enable confidential compute"
  type        = bool
  default     = false
}

# Instance Template Configuration
variable "create_template" {
  description = "Whether to create an instance template"
  type        = bool
  default     = false
}

variable "can_ip_forward" {
  description = "Enable IP forwarding"
  type        = bool
  default     = false
}

# Individual Instances Configuration
variable "instances" {
  description = "Map of instances to create"
  type        = map(any)
  default     = {}
}

# Instance Group Configuration
variable "create_instance_group" {
  description = "Whether to create an instance group"
  type        = bool
  default     = false
}

variable "instance_group_target_size" {
  description = "Target size for the instance group"
  type        = number
  default     = 1
}

variable "named_ports" {
  description = "Named ports for the instance group"
  type = list(object({
    name = string
    port = number
  }))
  default = []
}

variable "health_check_id" {
  description = "Health check ID for auto-healing"
  type        = string
  default     = ""
}

variable "health_check_initial_delay" {
  description = "Initial delay for health check in seconds"
  type        = number
  default     = 300
}

# Update Policy Configuration
variable "update_policy_type" {
  description = "Update policy type"
  type        = string
  default     = "OPPORTUNISTIC"
}

variable "update_policy_minimal_action" {
  description = "Minimal action for update policy"
  type        = string
  default     = "REFRESH"
}

variable "update_policy_most_disruptive_action" {
  description = "Most disruptive action allowed"
  type        = string
  default     = "REPLACE"
}

variable "update_policy_max_surge_fixed" {
  description = "Max surge for updates"
  type        = number
  default     = 3
}

variable "update_policy_max_unavailable_fixed" {
  description = "Max unavailable during updates"
  type        = number
  default     = 0
}

variable "update_policy_replacement_method" {
  description = "Replacement method for updates"
  type        = string
  default     = "SUBSTITUTE"
}

# Other Configuration
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "additional_metadata" {
  description = "Additional metadata for instances"
  type        = map(string)
  default     = {}
}

variable "allow_stopping_for_update" {
  description = "Allow stopping instance for updates"
  type        = bool
  default     = true
}