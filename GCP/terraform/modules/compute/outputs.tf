# modules/compute/outputs.tf

# Service Account Outputs
output "service_account_email" {
  description = "Email of the service account"
  value       = var.create_service_account ? google_service_account.instance_sa[0].email : var.service_account_email
}

output "service_account_id" {
  description = "ID of the service account"
  value       = var.create_service_account ? google_service_account.instance_sa[0].id : null
}

# Instance Template Outputs
output "instance_template_id" {
  description = "ID of the instance template"
  value       = var.create_template ? google_compute_instance_template.template[0].id : null
}

output "instance_template_self_link" {
  description = "Self-link of the instance template"
  value       = var.create_template ? google_compute_instance_template.template[0].self_link : null
}

# Individual Instance Outputs
output "instances" {
  description = "Map of instance names to their attributes"
  value = {
    for k, v in google_compute_instance.instances : k => {
      id               = v.id
      self_link        = v.self_link
      instance_id      = v.instance_id
      zone             = v.zone
      machine_type     = v.machine_type
      private_ip       = v.network_interface[0].network_ip
      public_ip        = length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : null
      tags             = v.tags
      labels           = v.labels
      metadata         = v.metadata
      service_account  = v.service_account[0].email
    }
  }
}

output "instance_ids" {
  description = "Map of instance names to IDs"
  value       = { for k, v in google_compute_instance.instances : k => v.id }
}

output "instance_self_links" {
  description = "Map of instance names to self-links"
  value       = { for k, v in google_compute_instance.instances : k => v.self_link }
}

output "instance_private_ips" {
  description = "Map of instance names to private IPs"
  value       = { for k, v in google_compute_instance.instances : k => v.network_interface[0].network_ip }
}

output "instance_public_ips" {
  description = "Map of instance names to public IPs"
  value = {
    for k, v in google_compute_instance.instances : k => 
    length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : null
  }
}

# Instance Group Outputs
output "instance_group_id" {
  description = "ID of the instance group manager"
  value       = var.create_instance_group ? google_compute_instance_group_manager.mig[0].id : null
}

output "instance_group_self_link" {
  description = "Self-link of the instance group manager"
  value       = var.create_instance_group ? google_compute_instance_group_manager.mig[0].self_link : null
}

output "instance_group_instance_group" {
  description = "Instance group URL"
  value       = var.create_instance_group ? google_compute_instance_group_manager.mig[0].instance_group : null
}

# SSH Commands Output (for Linux instances)
output "ssh_commands" {
  description = "SSH commands for Linux instances"
  value = {
    for k, v in google_compute_instance.instances : k => 
    "ssh -i <private_key_path> ${var.ssh_username}@${length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : v.network_interface[0].network_ip}"
    if lookup(v.labels, "os-type", var.os_type) == "linux"
  }
}

# RDP Commands Output (for Windows instances)
output "rdp_commands" {
  description = "RDP commands for Windows instances"
  value = {
    for k, v in google_compute_instance.instances : k => 
    "mstsc /v:${length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : v.network_interface[0].network_ip}"
    if lookup(v.labels, "os-type", var.os_type) == "windows"
  }
}

# Ansible Inventory Output
output "ansible_inventory" {
  description = "Ansible inventory entries for instances"
  value = join("\n", concat(
    ["[linux_instances]"],
    [for k, v in google_compute_instance.instances : 
      "${k} ansible_host=${length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : v.network_interface[0].network_ip} ansible_user=${var.ssh_username}"
      if lookup(v.labels, "os-type", var.os_type) == "linux"
    ],
    ["", "[windows_instances]"],
    [for k, v in google_compute_instance.instances : 
      "${k} ansible_host=${length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : v.network_interface[0].network_ip}"
      if lookup(v.labels, "os-type", var.os_type) == "windows"
    ],
    ["", "[windows_instances:vars]"],
    ["ansible_user=brine"],
    ["ansible_password=Bravedemo123."],
    ["ansible_connection=winrm"],
    ["ansible_winrm_transport=ntlm"],
    ["ansible_winrm_server_cert_validation=ignore"]
  ))
}