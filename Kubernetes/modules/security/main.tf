# modules/security/main.tf

locals {
  all_firewall_rules = merge(
    {
      allow-internal = {
        description = "Allow internal traffic on all ports"
        direction   = "INGRESS"
        priority    = 1000
        source_ranges = var.internal_ranges
        target_tags = var.target_tags
        allow = [
          {
            protocol = "tcp"
            ports    = ["0-65535"]
          },
          {
            protocol = "udp"
            ports    = ["0-65535"]
          },
          {
            protocol = "icmp"
            ports    = []
          }
        ]
      }
    },
    length(var.ssh_source_ranges) > 0 ? {
      allow-ssh = {
        description = "Allow SSH access"
        direction   = "INGRESS"
        priority    = 1000
        source_ranges = var.ssh_source_ranges
        target_tags = var.target_tags
        allow = [
          {
            protocol = "tcp"
            ports    = ["22"]
          }
        ]
      }
    } : {},
    length(var.rdp_source_ranges) > 0 ? {
      allow-rdp = {
        description = "Allow RDP access"
        direction   = "INGRESS"
        priority    = 1000
        source_ranges = var.rdp_source_ranges
        target_tags = var.target_tags
        allow = [
          {
            protocol = "tcp"
            ports    = ["3389"]
          }
        ]
      }
    } : {},
    length(var.winrm_source_ranges) > 0 ? {
      allow-winrm = {
        description = "Allow WinRM access"
        direction   = "INGRESS"
        priority    = 1000
        source_ranges = var.winrm_source_ranges
        target_tags = var.target_tags
        allow = [
          {
            protocol = "tcp"
            ports    = ["5985", "5986"]
          }
        ]
      }
    } : {},
    var.custom_firewall_rules
  )
}

# Firewall Rules
resource "google_compute_firewall" "rules" {
  for_each = local.all_firewall_rules
  
  name        = "${var.network_name}-${each.key}"
  network     = var.network_name
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority
  project     = var.project_id
  
  source_ranges = lookup(each.value, "source_ranges", [])
  source_tags   = lookup(each.value, "source_tags", [])
  target_tags   = lookup(each.value, "target_tags", var.target_tags)
  
  dynamic "allow" {
    for_each = lookup(each.value, "allow", [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", [])
    }
  }
  
  dynamic "deny" {
    for_each = lookup(each.value, "deny", null) != null ? lookup(each.value, "deny", []) : []
    content {
      protocol = deny.value.protocol
      ports    = lookup(deny.value, "ports", [])
    }
  }
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Outputs
output "firewall_rules" {
  description = "Created firewall rules"
  value = {
    for k, v in google_compute_firewall.rules : k => {
      id   = v.id
      name = v.name
    }
  }
}