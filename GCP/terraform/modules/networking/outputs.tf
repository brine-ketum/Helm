# modules/networking/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The URI of the VPC"
  value       = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

output "subnet_self_links" {
  description = "Map of subnet names to self links"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.self_link }
}

output "subnet_regions" {
  description = "Map of subnet names to regions"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.region }
}

output "subnet_ip_ranges" {
  description = "Map of subnet names to IP CIDR ranges"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.ip_cidr_range }
}

output "nat_ip" {
  description = "The external IP address of the NAT gateway"
  value       = var.create_nat_gateway ? google_compute_router_nat.nat[0].id : null
}