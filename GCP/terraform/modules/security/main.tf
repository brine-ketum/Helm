# modules/security/main.tf

locals {
  # Default firewall rules for common scenarios
  _all_default_rules = {
    allow-ssh = {
      description   = "Allow SSH from specified IPs"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = var.ssh_source_ranges
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    }
    
    allow-rdp = {
      description   = "Allow RDP from specified IPs"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = var.rdp_source_ranges
      allow = [{
        protocol = "tcp"
        ports    = ["3389"]
      }]
    }
    
    allow-winrm = {
      description   = "Allow WinRM from specified IPs"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = var.winrm_source_ranges
      allow = [{
        protocol = "tcp"
        ports    = ["5985", "5986"]
      }]
    }
    
    allow-internal = {
      description   = "Allow all internal traffic"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = var.internal_ranges
      allow = [{
        protocol = "all"
        ports    = []
      }]
    }
    
    allow-health-checks = {
      description   = "Allow Google Cloud health checks"
      direction     = "INGRESS"
      priority      = 900
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
      allow = [{
        protocol = "tcp"
        ports    = []
      }]
    }
    
    allow-iap = {
      description   = "Allow IAP for SSH"
      direction     = "INGRESS"
      priority      = 900
      source_ranges = ["35.235.240.0/20"]
      allow = [{
        protocol = "tcp"
        ports    = ["22", "3389"]
      }]
    }
    
    default-egress = {
      description        = "Default egress rule"
      direction          = "EGRESS"
      priority           = 1000
      destination_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "all"
        ports    = []
      }]
    }
  }
  
  # Filter default rules based on enable_default_rules variable
  default_firewall_rules = {
    for k, v in local._all_default_rules : k => v
    if var.enable_default_rules
  }
  
  # Combine default rules with custom rules
  all_firewall_rules = merge(
    local.default_firewall_rules,
    var.custom_firewall_rules
  )
}

# Firewall rules
resource "google_compute_firewall" "rules" {
  for_each = local.all_firewall_rules

  name        = "${var.network_name}-${each.key}"
  network     = var.network_name
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges      = each.value.direction == "INGRESS" ? lookup(each.value, "source_ranges", null) : null
  destination_ranges = each.value.direction == "EGRESS" ? lookup(each.value, "destination_ranges", null) : null
  
  # Use either tags OR service accounts, not both
  # If source_service_accounts is specified, don't use tags
  source_tags      = lookup(each.value, "source_service_accounts", null) == null ? lookup(each.value, "source_tags", null) : null
  target_tags      = lookup(each.value, "target_service_accounts", null) == null ? lookup(each.value, "target_tags", var.target_tags) : null
  
  # Use service accounts only if tags are not being used
  source_service_accounts = lookup(each.value, "source_service_accounts", null)
  target_service_accounts = lookup(each.value, "target_service_accounts", null)

  dynamic "allow" {
    for_each = lookup(each.value, "allow", [])
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = lookup(each.value, "deny", [])
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  dynamic "log_config" {
    for_each = lookup(each.value, "enable_logging", false) ? [1] : []
    content {
      metadata = lookup(each.value, "logging_metadata", "INCLUDE_ALL_METADATA")
    }
  }

  disabled = lookup(each.value, "disabled", false)

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}