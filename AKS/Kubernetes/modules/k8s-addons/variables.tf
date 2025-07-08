# modules/k8s-addons/variables.tf

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

# Addon installation flags
variable "install_nginx_ingress" {
  description = "Whether to install NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "install_cert_manager" {
  description = "Whether to install cert-manager"
  type        = bool
  default     = true
}

variable "install_external_dns" {
  description = "Whether to install ExternalDNS"
  type        = bool
  default     = true
}

variable "install_cluster_autoscaler" {
  description = "Whether to install Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "install_metrics_server" {
  description = "Whether to install Metrics Server"
  type        = bool
  default     = true
}

variable "install_prometheus" {
  description = "Whether to install Prometheus"
  type        = bool
  default     = false
}

variable "install_grafana" {
  description = "Whether to install Grafana"
  type        = bool
  default     = false
}

variable "install_jaeger" {
  description = "Whether to install Jaeger"
  type        = bool
  default     = false
}

variable "install_argocd" {
  description = "Whether to install ArgoCD"
  type        = bool
  default     = false
}

# DNS Configuration
variable "dns_zone_name" {
  description = "Name of the Cloud DNS zone"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the cluster"
  type        = string
  default     = ""
}

# Namespace Configuration
variable "prometheus_namespace" {
  description = "Namespace for Prometheus"
  type        = string
  default     = "monitoring"
}

variable "grafana_namespace" {
  description = "Namespace for Grafana"
  type        = string
  default     = "monitoring"
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

# Helm Chart Versions
variable "nginx_ingress_version" {
  description = "NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "4.8.3"
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "1.13.2"
}

variable "external_dns_version" {
  description = "ExternalDNS Helm chart version"
  type        = string
  default     = "1.13.1"
}

variable "metrics_server_version" {
  description = "Metrics Server Helm chart version"
  type        = string
  default     = "3.11.0"
}

variable "prometheus_version" {
  description = "Prometheus Helm chart version"
  type        = string
  default     = "25.8.0"
}

variable "grafana_version" {
  description = "Grafana Helm chart version"
  type        = string
  default     = "7.0.8"
}

variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.4"
}