# modules/gke/variables.tf

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "location" {
  description = "Location for the GKE cluster"
  type        = string
}

variable "region" {
  description = "Region for the GKE cluster"
  type        = string
}

variable "network" {
  description = "VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the pods secondary range"
  type        = string
  default     = "pods"
}

variable "services_range_name" {
  description = "Name of the services secondary range"
  type        = string
  default     = "services"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "latest"
}

variable "enable_private_nodes" {
  description = "Enable private nodes"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for master nodes"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_global_access" {
  description = "Enable master global access"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "Master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "enable_shielded_nodes" {
  description = "Enable shielded nodes"
  type        = bool
  default     = true
}

variable "enable_pod_security_policy" {
  description = "Enable pod security policy"
  type        = bool
  default     = false
}

variable "horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "http_load_balancing" {
  description = "Enable HTTP load balancing"
  type        = bool
  default     = true
}

variable "network_policy_config" {
  description = "Enable network policy config"
  type        = bool
  default     = true
}

variable "dns_cache_config" {
  description = "Enable DNS cache config"
  type        = bool
  default     = true
}

variable "filestore_csi_driver" {
  description = "Enable Filestore CSI driver"
  type        = bool
  default     = false
}

variable "gce_pd_csi_driver" {
  description = "Enable GCE PD CSI driver"
  type        = bool
  default     = true
}

variable "cluster_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = false
}

variable "cluster_autoscaling_cpu_min" {
  description = "Minimum CPU for cluster autoscaling"
  type        = number
  default     = 1
}

variable "cluster_autoscaling_cpu_max" {
  description = "Maximum CPU for cluster autoscaling"
  type        = number
  default     = 100
}

variable "cluster_autoscaling_memory_min" {
  description = "Minimum memory for cluster autoscaling"
  type        = number
  default     = 1
}

variable "cluster_autoscaling_memory_max" {
  description = "Maximum memory for cluster autoscaling"
  type        = number
  default     = 1000
}

variable "maintenance_start_time" {
  description = "Maintenance start time"
  type        = string
  default     = "2025-01-11T09:00:00Z"  # Next Saturday 9:00 AM UTC
}

variable "maintenance_end_time" {
  description = "Maintenance end time"
  type        = string
  default     = "2025-01-11T17:00:00Z"  # Next Saturday 5:00 PM UTC (8 hours window)
}

variable "maintenance_recurrence" {
  description = "Maintenance recurrence"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SA,SU"  # Every Saturday and Sunday
}
variable "logging_service" {
  description = "Logging service"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "Monitoring service"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "create_service_account" {
  description = "Create service account for nodes"
  type        = bool
  default     = true
}

variable "node_service_account" {
  description = "Node service account email"
  type        = string
  default     = ""
}

variable "node_pools" {
  description = "Node pool configurations"
  type        = any
  default     = {}
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}