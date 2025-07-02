# modules/networking/main.tf

# VPC Network
resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  auto_create_subnetworks        = false
  delete_default_routes_on_create = false
  description                    = var.vpc_description
  routing_mode                   = var.routing_mode
  mtu                           = var.mtu

  timeouts {
    create = "30m"
    update = "40m"
    delete = "30m"
  }
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name                     = each.key
  ip_cidr_range           = each.value.ip_cidr_range
  region                  = each.value.region
  network                 = google_compute_network.vpc.id
  description             = lookup(each.value, "description", null)
  private_ip_google_access = lookup(each.value, "private_ip_google_access", true)
  
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
      aggregation_interval = lookup(each.value, "flow_logs_interval", "INTERVAL_10_MIN")
      flow_sampling       = lookup(each.value, "flow_logs_sampling", 0.5)
      metadata            = lookup(each.value, "flow_logs_metadata", "INCLUDE_ALL_METADATA")
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Cloud NAT (optional)
resource "google_compute_router" "router" {
  count = var.create_nat_gateway ? 1 : 0

  name    = "${var.vpc_name}-router"
  network = google_compute_network.vpc.id
  region  = var.nat_region

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router[0].name
  region                             = google_compute_router.router[0].region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Private Service Connection (for Google APIs)
resource "google_compute_global_address" "private_ip_address" {
  count = var.enable_private_service_connect ? 1 : 0

  name          = "${var.vpc_name}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.enable_private_service_connect ? 1 : 0

  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}