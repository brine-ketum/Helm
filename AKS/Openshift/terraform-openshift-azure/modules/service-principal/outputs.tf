# modules/service-principal/outputs.tf

output "application_id" {
  description = "The Application ID (client_id)"
  value       = azuread_application.main.client_id
}

output "object_id" {
  description = "The Object ID of the service principal"
  value       = azuread_service_principal.main.object_id
}

output "password" {
  description = "The password for the service principal"
  value       = azuread_service_principal_password.main.value
  sensitive   = true
}

output "tenant_id" {
  description = "The tenant ID"
  value       = azuread_service_principal.main.application_tenant_id
}
