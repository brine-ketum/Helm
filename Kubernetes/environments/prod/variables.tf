# environments/prod/variables.tf

# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west2"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "brinek"
}

# Cluster Configuration
variable "cluster_location" {
  description = "Location for the GKE cluster (region or zone)"
  type        = string
  default     = "us-west2"
}

variable "min_node_count" {
  description = "Minimum number of nodes in the primary node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the primary node pool"
  type        = number
  default     = 10
}

variable "initial_node_count" {
  description = "Initial number of nodes in the primary node pool"
  type        = number
  default     = 2
}

# Network Configuration
variable "allowed_ssh_ips" {
  description = "List of IPs allowed for SSH access to bastion/debug pods"
  type        = list(string)
  default     = []
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  ]
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs"
  type        = bool
  default     = true
}

# Registry Configuration
variable "registry_location" {
  description = "Location for the Artifact Registry"
  type        = string
  default     = "us-west2"
}

# DNS Configuration
variable "dns_zone_name" {
  description = "Name of the Cloud DNS zone"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the cluster"
  type        = string
  default     = ""
}

# Addon Configuration
variable "install_prometheus" {
  description = "Whether to install Prometheus monitoring"
  type        = bool
  default     = true
}

variable "install_grafana" {
  description = "Whether to install Grafana dashboards"
  type        = bool
  default     = true
}

variable "install_jaeger" {
  description = "Whether to install Jaeger tracing"
  type        = bool
  default     = false
}

variable "install_argocd" {
  description = "Whether to install ArgoCD for GitOps"
  type        = bool
  default     = true
}

# Additional Configuration
variable "additional_labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}