# Subscription and Resource Group Information
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region for the resources"
}

# Virtual Network and Subnet Information
variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
}

variable "mgmt_subnet_name" {
  type        = string
  description = "Name of the management subnet"
}

variable "mgmt_subnet_prefix" {
  type        = list(string)
  description = "Address prefix for the management subnet"
}

variable "traffic_subnet_name" {
  type        = string
  description = "Name of the traffic subnet"
}

variable "traffic_subnet_prefix" {
  type        = list(string)
  description = "Address prefix for the traffic subnet"
}

variable "tools_subnet_name" {
  type        = string
  description = "Name of the tools subnet"
}

variable "tools_subnet_prefix" {
  type        = list(string)
  description = "Address prefix for the tools subnet"
}

# Network Security Group
variable "nsg_name" {
  type        = string
  description = "Name of the network security group"
}

# Platform Load Balancer (PLB)
variable "plb_name" {
  type        = string
  description = "Name of the platform load balancer"
}

variable "plb_frontend_ip_name" {
  type        = string
  description = "Name of the frontend IP configuration for PLB"
}

variable "plb_public_ip_name" {
  type        = string
  description = "Name of the public IP for PLB"
}

variable "plb_probe_name" {
  type        = string
  description = "Name of the health probe for PLB"
}

variable "plb_probe_protocol" {
  type        = string
  description = "Protocol for PLB health probe"
}

variable "plb_probe_port" {
  type        = number
  description = "Port for PLB health probe"
}

variable "plb_probe_interval" {
  type        = number
  description = "Interval for PLB health probe"
}

variable "plb_probe_count" {
  type        = number
  description = "Number of probes for PLB health check"
}

variable "plb_backend_pool_name" {
  type        = string
  description = "Name of the backend pool for PLB"
}

variable "plb_lb_rule_name" {
  type        = string
  description = "Name of the PLB rule"
}

variable "plb_rule_protocol" {
  type        = string
  description = "Protocol for PLB rule"
}

variable "plb_rule_frontend_port" {
  type        = number
  description = "Frontend port for PLB rule"
}

variable "plb_rule_backend_port" {
  type        = number
  description = "Backend port for PLB rule"
}

# Gateway Load Balancer (GWLB)
variable "gwlb_name" {
  type        = string
  description = "Name of the gateway load balancer"
}

variable "gwlb_frontend_ip_name" {
  type        = string
  description = "Name of the frontend IP configuration for GWLB"
}

variable "gwlb_probe_name" {
  type        = string
  description = "Name of the health probe for GWLB"
}

variable "gwlb_probe_protocol" {
  type        = string
  description = "Protocol for GWLB health probe"
}

variable "gwlb_probe_port" {
  type        = number
  description = "Port for GWLB health probe"
}

variable "gwlb_probe_interval" {
  type        = number
  description = "Interval for GWLB health probe"
}

variable "gwlb_probe_count" {
  type        = number
  description = "Number of probes for GWLB health check"
}

variable "gwlb_lb_rule_name" {
  type        = string
  description = "Name of the GWLB rule"
}

variable "gwlb_rule_protocol" {
  type        = string
  description = "Protocol for GWLB rule"
}

variable "gwlb_rule_frontend_port" {
  type        = number
  description = "Frontend port for GWLB rule"
}

variable "gwlb_rule_backend_port" {
  type        = number
  description = "Backend port for GWLB rule"
}

# vPacketStack Network Interfaces
variable "vpb_mgmt_nic_name" {
  type        = string
  description = "Name of the management NIC for vPacketStack"
}

variable "vpb_traffic_nic_name" {
  type        = string
  description = "Name of the traffic NIC for vPacketStack"
}

variable "vpb_tools_nic_name" {
  type        = string
  description = "Name of the tools NIC for vPacketStack"
}

variable "vpacketstack_ipconfig_mgmt" {
  type        = string
  description = "Name of the management IP configuration"
}

variable "vpacketstack_ipconfig_traffic" {
  type        = string
  description = "Name of the traffic IP configuration"
}

variable "vpacketstack_ipconfig_tools" {
  type        = string
  description = "Name of the tools IP configuration"
}

# vPacketStack VM Information
variable "vpb_vm_name" {
  type        = string
  description = "Name of the vPacketStack VM"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM"
}

# variable "vpb_installer_path" {
#   type       = string
#   description = "path to vpb installer script"
# }

variable "vpb_nsg" {
  type = string
  description = "vpb SG"
}
# OS Disk Configuration
variable "os_disk_caching" {
  type        = string
  description = "Caching setting for the OS disk"
  default     = "ReadWrite"
}

variable "os_disk_size_gb" {
  type        = number
  description = "Size of the OS disk in GB"
}

variable "os_disk_storage_account_type" {
  type        = string
  description = "Storage account type for the OS disk"
}

# OS Image Information
variable "image_publisher" {
  type        = string
  description = "Publisher of the OS image"
  default     = "Canonical"
}

variable "image_offer" {
  type        = string
  description = "Offer of the OS image"
  default     = "0001-com-ubuntu-server-focal"
}

variable "image_sku" {
  type        = string
  description = "SKU of the OS image"
  default     = "20_04-lts"
}

variable "image_version" {
  type        = string
  description = "Version of the OS image"
  default     = "latest"
}

# Public IP for VM
variable "vpacketstack_public_ip_name" {
  type        = string
  description = "Name of the public IP for vPacketStack VM"
}

# Admin user name and password
variable "admin_username" {
  type        = string
  description = "Admin username for the virtual machines"
  sensitive   = true
}

variable "admin_password" {
  type        = string
  description = "Admin password for the virtual machines"
  sensitive   = true
}


# Web Workload Information
# variable "web_workload_nic_name" {
#   type        = string
#   description = "Name of the NIC for the Web Workload"
# }

# variable "web_workload_ipconfig_name" {
#   type        = string
#   description = "Name of the IP configuration for the Web Workload NIC"
# }

# variable "web_workload_vm_name" {
#   type        = string
#   description = "Name of the Web Workload VM"
# }

# variable "wkload_nsg" {
#   type        = string
#   description = "Security Group of Workload VM"
# }

# variable "web_workload_vm_size" {
#   type        = string
#   description = "Size of the Web Workload VM"
# }

# variable "web_workload_os_disk_size_gb" {
#   type        = number
#   description = "Size of the OS disk for Web Workload VM in GB"
# }


# CLM VM Information
variable "clm_nic_name" {
  type        = string
  description = "Name of the NIC for the CLM VM"
}

variable "clm_ipconfig_name" {
  type        = string
  description = "Name of the IP configuration for the CLM VM NIC"
}

variable "clm_vm_name" {
  type        = string
  description = "Name of the CLM VM"
}

variable "clm_vm_size" {
  type        = string
  description = "Size of the CLM VM (4 vCPUs, 16 GB RAM)"
}

variable "installer_path" {
  type        = string
  description = "Path to the CloudLens installer script on the local machine."
}

variable "clm_os_disk_size_gb" {
  type        = number
  description = "Size of the root disk for the CLM VM (at least 100 GB)"
}

variable "clm_nsg" {
  type        = string
  description = "clm SG "
}

# Environment Information
variable "env" {
  type        = string
  description = "Environment name (e.g., dev, production)"
}
