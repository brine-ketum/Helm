# environments/prod/outputs.tf

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = module.networking.vpc_name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.networking.subnet_ids
}

# GKE Cluster Outputs
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = module.gke.location
}

output "cluster_zones" {
  description = "The zones of the GKE cluster"
  value       = module.gke.node_zones
}

# Node Pool Outputs
output "node_pools" {
  description = "Information about the node pools"
  value       = module.gke.node_pools
}

output "node_pool_instance_group_urls" {
  description = "Instance group URLs for node pools"
  value       = module.gke.node_pool_instance_group_urls
}

# Registry Outputs
output "registry_url" {
  description = "The URL of the Artifact Registry"
  value       = module.registry.registry_url
}

output "registry_id" {
  description = "The ID of the Artifact Registry"
  value       = module.registry.registry_id
}

# Service Account Outputs
output "gke_service_account_email" {
  description = "Email of the GKE service account"
  value       = google_service_account.gke_service_account.email
}

# kubectl Configuration Command
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --location ${module.gke.location} --project ${var.project_id}"
}

# Kubernetes Connection Info
output "kubernetes_cluster_info" {
  description = "Kubernetes cluster connection information"
  value = {
    cluster_name = module.gke.cluster_name
    endpoint     = module.gke.endpoint
    location     = module.gke.location
    project_id   = var.project_id
  }
  sensitive = true
}

# Registry Connection Info
output "registry_connection_info" {
  description = "Container registry connection information"
  value = {
    registry_url = module.registry.registry_url
    docker_command = "docker tag <image> ${module.registry.registry_url}/<image>"
    push_command = "docker push ${module.registry.registry_url}/<image>"
    configure_docker = "gcloud auth configure-docker ${var.registry_location}-docker.pkg.dev"
  }
}

# Addon Status
output "installed_addons" {
  description = "Status of installed Kubernetes addons"
  value = {
    nginx_ingress     = module.k8s_addons.nginx_ingress_status
    cert_manager      = module.k8s_addons.cert_manager_status
    external_dns      = module.k8s_addons.external_dns_status
    cluster_autoscaler = module.k8s_addons.cluster_autoscaler_status
    prometheus        = module.k8s_addons.prometheus_status
    grafana          = module.k8s_addons.grafana_status
    argocd           = module.k8s_addons.argocd_status
  }
}

# Access URLs
output "access_urls" {
  description = "URLs to access various services"
  value = {
    grafana_url     = var.domain_name != "" ? "https://grafana.${var.domain_name}" : "kubectl port-forward -n monitoring svc/grafana 3000:80"
    prometheus_url  = var.domain_name != "" ? "https://prometheus.${var.domain_name}" : "kubectl port-forward -n monitoring svc/prometheus-server 9090:80"
    argocd_url     = var.domain_name != "" ? "https://argocd.${var.domain_name}" : "kubectl port-forward -n argocd svc/argocd-server 8080:80"
  }
}

# Firewall Rules
output "firewall_rules" {
  description = "Created firewall rules"
  value       = module.security.firewall_rules
}