# modules/security/outputs.tf

output "firewall_rules" {
  description = "Map of firewall rule names to their attributes"
  value = {
    for k, v in google_compute_firewall.rules : 
    k => {
      id          = v.id
      name        = v.name
      self_link   = v.self_link
      direction   = v.direction
      priority    = v.priority
      source_ranges = v.source_ranges
      target_tags = v.target_tags
    }
  }
}

output "firewall_rule_ids" {
  description = "Map of firewall rule names to IDs"
  value       = { for k, v in google_compute_firewall.rules : k => v.id }
}

output "firewall_rule_self_links" {
  description = "Map of firewall rule names to self links"
  value       = { for k, v in google_compute_firewall.rules : k => v.self_link }
}