# modules/registry/outputs.tf

output "registry_id" {
  description = "The ID of the Container Registry"
  value       = azurerm_container_registry.main.id
}

output "registry_name" {
  description = "The name of the Container Registry"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "The login server of the Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "The admin username of the Container Registry"
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_username : null
}

output "admin_password" {
  description = "The admin password of the Container Registry"
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_password : null
  sensitive   = true
}

output "identity_principal_id" {
  description = "The Principal ID of the system assigned identity"
  value       = azurerm_container_registry.main.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "The Tenant ID of the system assigned identity"
  value       = azurerm_container_registry.main.identity[0].tenant_id
}

output "webhook_ids" {
  description = "Map of webhook names to IDs"
  value = {
    for k, v in azurerm_container_registry_webhook.main : k => v.id
  }
}

output "scope_map_ids" {
  description = "Map of scope map names to IDs"
  value = {
    for k, v in azurerm_container_registry_scope_map.main : k => v.id
  }
}

output "token_ids" {
  description = "Map of token names to IDs"
  value = {
    for k, v in azurerm_container_registry_token.main : k => v.id
  }
}
