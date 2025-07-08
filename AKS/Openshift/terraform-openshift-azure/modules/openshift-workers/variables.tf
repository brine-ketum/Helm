# modules/openshift-workers/variables.tf

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "cluster_name" {
  description = "OpenShift cluster name"
  type        = string
}

variable "worker_profile_name" {
  description = "Name of the worker profile"
  type        = string
}

variable "worker_vm_size" {
  description = "VM size for workers"
  type        = string
}

variable "worker_vm_disk_size_gb" {
  description = "Disk size for workers"
  type        = number
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "worker_subnet_id" {
  description = "Subnet ID for workers"
  type        = string
}