# modules/security/outputs.tf

output "network_security_group_id" {
  description = "The ID of the Network Security Group"
  value       = azurerm_network_security_group.main.id
}

output "network_security_group_name" {
  description = "The name of the Network Security Group"
  value       = azurerm_network_security_group.main.name
}

output "security_rules" {
  description = "Map of security rule names to IDs"
  value = merge(
    {
      ssh         = var.create_default_rules && length(var.ssh_source_addresses) > 0 ? azurerm_network_security_rule.ssh[0].id : null
      internal    = var.create_default_rules ? azurerm_network_security_rule.internal[0].id : null
    },
    {
      for k, v in azurerm_network_security_rule.custom : k => v.id
    }
  )
}

output "application_security_group_ids" {
  description = "Map of application security group names to IDs"
  value = {
    for k, v in azurerm_application_security_group.main : k => v.id
  }
}
