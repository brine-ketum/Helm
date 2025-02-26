variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "vm_name" {
  description = "Name of the VM."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM."
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Size of the VM."
  type        = string
  default     = "Standard_DS2_v2" # This effectively supports 4 vCPUs and 16GB RAM
}

variable "image_reference" {
  description = "Image reference for VM deployment."
  type        = map(string)
}

variable "installer_url" {
  description = "CloudLens installer script URL."
  type        = string
}

variable "installer_version" {
  description = "Version of the CloudLens installer."
  type        = string
  default     = "latest" # Define desired version
}

variable "wait_duration" {
  description = "Duration to wait for CloudLens Manager availability."
  type        = string
  default     = "20m" # Adjustable waiting period
}