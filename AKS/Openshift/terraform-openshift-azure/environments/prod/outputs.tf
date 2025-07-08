# environments/prod/outputs.tf

# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# VNet Outputs
output "vnet_id" {
  description = "The ID of the VNet"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "The name of the VNet"
  value       = module.networking.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.networking.subnet_ids
}

# OpenShift Cluster Outputs
output "cluster_name" {
  description = "The name of the OpenShift cluster"
  value       = module.openshift.cluster_name
}

output "cluster_id" {
  description = "The ID of the OpenShift cluster"
  value       = module.openshift.cluster_id
}

output "console_url" {
  description = "The console URL of the OpenShift cluster"
  value       = module.openshift.console_url
}

output "api_server_url" {
  description = "The API server URL of the OpenShift cluster"
  value       = module.openshift.api_server_url
}

output "console_username" {
  description = "Username for OpenShift console (kubeadmin)"
  value       = module.openshift.console_username
}

output "console_password" {
  description = "Password for OpenShift console"
  value       = module.openshift.console_password
  sensitive   = true
}

# Registry Outputs
output "registry_login_server" {
  description = "The login server of the Container Registry"
  value       = module.registry.login_server
}

output "registry_id" {
  description = "The ID of the Container Registry"
  value       = module.registry.registry_id
}

# Key Vault Outputs
output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

# Storage Account Outputs
output "storage_account_name" {
  description = "Name of the storage account for OpenShift registry"
  value       = azurerm_storage_account.registry.name
}

# OpenShift CLI Commands
output "openshift_login_command" {
  description = "Command to login to OpenShift"
  value       = "oc login ${module.openshift.api_server_url} -u ${module.openshift.console_username} -p <password>"
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "oc login ${module.openshift.api_server_url} && oc config view --raw > ~/.kube/config"
}

# Service Principal Information
output "service_principal_id" {
  description = "The Application ID of the service principal"
  value       = local.service_principal_client_id
}

# DNS Information
output "dns_zone_name_servers" {
  description = "Name servers for the DNS zone (if created)"
  value       = var.create_dns_zone ? azurerm_dns_zone.main[0].name_servers : []
}

# Access Information
output "access_info" {
  description = "OpenShift cluster access information"
  value = {
    console_url = module.openshift.console_url
    api_url     = module.openshift.api_server_url
    username    = module.openshift.console_username
    password_location = "Azure Key Vault: ${azurerm_key_vault.main.name}"
  }
}