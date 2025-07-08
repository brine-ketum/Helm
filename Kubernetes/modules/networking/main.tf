# modules/networking/main.tf

# VPC
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  description             = var.vpc_description
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  project                 = var.project_id
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets
  
  name          = each.key
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc.id
  description   = lookup(each.value, "description", null)
  project       = var.project_id
  
  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ip_ranges", [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
  
  dynamic "log_config" {
    for_each = lookup(each.value, "enable_flow_logs", false) ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling       = 0.5
      metadata           = "INCLUDE_ALL_METADATA"
    }
  }
  
  private_ip_google_access = true
}

# Cloud Router (for NAT)
resource "google_compute_router" "router" {
  count = var.create_nat_gateway ? 1 : 0
  
  name    = "${var.vpc_name}-router"
  region  = var.nat_region
  network = google_compute_network.vpc.id
  project = var.project_id
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  count = var.create_nat_gateway ? 1 : 0
  
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router[0].name
  region                             = google_compute_router.router[0].region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id
  
  log_config {
    enable = true
    filter = "ALL"
  }
}

# Outputs
output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "vpc_self_link" {
  value = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  value = {
    for k, v in google_compute_subnetwork.subnets : k => v.id
  }
}

output "subnet_self_links" {
  value = {
    for k, v in google_compute_subnetwork.subnets : k => v.self_link
  }
}

output "router_id" {
  value = var.create_nat_gateway ? google_compute_router.router[0].id : null
}

output "nat_id" {
  value = var.create_nat_gateway ? google_compute_router_nat.nat[0].id : null
}