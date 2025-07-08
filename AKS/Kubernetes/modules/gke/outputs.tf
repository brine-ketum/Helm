# modules/gke/outputs.tf

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "node_zones" {
  description = "Zones where nodes are located"
  value       = google_container_cluster.primary.node_locations
}

output "master_version" {
  description = "Master version of the GKE cluster"
  value       = google_container_cluster.primary.master_version
}

output "node_pools" {
  description = "Node pool information"
  value = {
    for k, v in google_container_node_pool.pools : k => {
      name               = v.name
      location           = v.location
      node_count         = v.node_count
      version            = v.version
      instance_group_urls = v.instance_group_urls
    }
  }
}

output "node_pool_instance_group_urls" {
  description = "Instance group URLs for node pools"
  value = {
    for k, v in google_container_node_pool.pools : k => v.instance_group_urls
  }
}

output "service_account" {
  description = "Service account used by nodes"
  value       = var.create_service_account ? google_service_account.default[0].email : var.node_service_account
}

output "network" {
  description = "Network used by the cluster"
  value       = google_container_cluster.primary.network
}

output "subnetwork" {
  description = "Subnetwork used by the cluster"
  value       = google_container_cluster.primary.subnetwork
}

output "cluster_autoscaling" {
  description = "Cluster autoscaling configuration"
  value       = google_container_cluster.primary.cluster_autoscaling
}

output "addons_config" {
  description = "Addons configuration"
  value       = google_container_cluster.primary.addons_config
}

output "workload_identity_config" {
  description = "Workload identity configuration"
  value       = google_container_cluster.primary.workload_identity_config
}