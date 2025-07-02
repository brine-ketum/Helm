# environments/prod/outputs.tf

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = module.networking.vpc_name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.networking.subnet_ids
}

# VM Outputs by Type
output "ubuntu_instances" {
  description = "Ubuntu VM details"
  value = {
    for k, v in module.compute.instances : k => v
    if can(regex("^ubuntu-vm-", k))
  }
}

output "rhel_instances" {
  description = "RHEL VM details"
  value = {
    for k, v in module.compute.instances : k => v
    if can(regex("^rhel-vm-", k))
  }
}

output "windows_instances" {
  description = "Windows VM details"
  value = {
    for k, v in module.compute.instances : k => v
    if can(regex("^windows-vm-", k))
  }
}

output "clms_instance" {
  description = "CLMS VM details"
  value       = module.clms_compute.instances["clms-vm"]
}

# Public IP Outputs
output "ubuntu_public_ips" {
  description = "Public IPs of Ubuntu VMs"
  value = [
    for k, v in module.compute.instance_public_ips : v
    if can(regex("^ubuntu-vm-", k)) && v != null
  ]
}

output "rhel_public_ips" {
  description = "Public IPs of RHEL VMs"
  value = [
    for k, v in module.compute.instance_public_ips : v
    if can(regex("^rhel-vm-", k)) && v != null
  ]
}

output "windows_public_ips" {
  description = "Public IPs of Windows VMs"
  value = [
    for k, v in module.compute.instance_public_ips : v
    if can(regex("^windows-vm-", k)) && v != null
  ]
}

output "clms_public_ip" {
  description = "Public IP of CLMS VM"
  value       = module.clms_compute.instance_public_ips["clms-vm"]
}

# SSH Instructions
output "ssh_instructions_ubuntu" {
  description = "SSH commands for Ubuntu VMs"
  value = [
    for k, v in module.compute.instances :
    "ssh -i ${var.ssh_private_key_path} ${var.ssh_username}@${v.public_ip}"
    if can(regex("^ubuntu-vm-", k)) && v.public_ip != null
  ]
}

output "ssh_instructions_rhel" {
  description = "SSH commands for RHEL VMs"
  value = [
    for k, v in module.compute.instances :
    "ssh -i ${var.ssh_private_key_path} ${var.ssh_username}@${v.public_ip}"
    if can(regex("^rhel-vm-", k)) && v.public_ip != null
  ]
}

output "ssh_instructions_clms" {
  description = "SSH command for CLMS VM"
  value       = "ssh -i ${var.ssh_private_key_path} ${var.ssh_username}@${module.clms_compute.instance_public_ips["clms-vm"]}"
}

# RDP Instructions
output "rdp_commands_windows" {
  description = "RDP commands for Windows VMs"
  value = [
    for k, v in module.compute.instances :
    "mstsc /v:${v.public_ip}"
    if can(regex("^windows-vm-", k)) && v.public_ip != null
  ]
}

# Ansible Inventory
output "ansible_inventory" {
  description = "Ansible inventory configuration"
  sensitive   = true  # Added this line to fix the sensitive value error
  value = templatefile("${path.module}/templates/ansible_inventory.tpl", {
    ubuntu_vms = {
      for k, v in module.compute.instances : k => v
      if can(regex("^ubuntu-vm-", k))
    }
    rhel_vms = {
      for k, v in module.compute.instances : k => v
      if can(regex("^rhel-vm-", k))
    }
    windows_vms = {
      for k, v in module.compute.instances : k => v
      if can(regex("^windows-vm-", k))
    }
    clms_vm            = module.clms_compute.instances["clms-vm"]
    ssh_username       = var.ssh_username
    ssh_private_key    = var.ssh_private_key_path
    windows_username   = var.windows_admin_username
    windows_password   = var.windows_admin_password
  })
}

# Firewall Rules
output "firewall_rules" {
  description = "Created firewall rules"
  value       = module.security.firewall_rules
}

# Service Account
output "compute_service_account" {
  description = "Service account used by compute instances"
  value       = module.compute.service_account_email
}