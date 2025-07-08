# modules/openshift/variables.tf

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location where the cluster will be created"
  type        = string
}

variable "cluster_name" {
  description = "The name of the OpenShift cluster"
  type        = string
}

variable "openshift_version" {
  description = "OpenShift version"
  type        = string
  default     = "4.13.23"
}

variable "domain" {
  description = "The domain for the cluster"
  type        = string
}

variable "pull_secret" {
  description = "Red Hat pull secret"
  type        = string
  sensitive   = true
}

variable "vnet_id" {
  description = "VNet ID"
  type        = string
}

variable "master_subnet_id" {
  description = "Subnet ID for master nodes"
  type        = string
}

variable "worker_subnet_id" {
  description = "Subnet ID for worker nodes"
  type        = string
}

variable "pod_cidr" {
  description = "CIDR for pod IPs"
  type        = string
  default     = "10.128.0.0/14"
}

variable "service_cidr" {
  description = "CIDR for service IPs"
  type        = string
  default     = "172.30.0.0/16"
}

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

variable "master_encryption_at_host" {
  description = "Enable encryption at host for master nodes"
  type        = bool
  default     = false
}

variable "worker_profile_name" {
  description = "Name of the worker profile"
  type        = string
  default     = "worker"
}

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
}

variable "worker_encryption_at_host" {
  description = "Enable encryption at host for worker nodes"
  type        = bool
  default     = false
}


variable "encryption_at_host" {
  description = "Enable encryption at host for all nodes"
  type        = bool
  default     = false
}

variable "api_server_visibility" {
  description = "API server visibility (Public or Private)"
  type        = string
  default     = "Public"
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server"
  type        = list(string)
  default     = []
}

variable "ingress_visibility" {
  description = "Ingress visibility (Public or Private)"
  type        = string
  default     = "Public"
}

variable "client_id" {
  description = "Service Principal client ID"
  type        = string
}

variable "client_secret" {
  description = "Service Principal client secret"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = map(string)
  default     = {}
}
