# environments/prod/main.tf

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Configure Kubernetes provider
data "google_client_config" "provider" {}

provider "kubernetes" {
  host  = "https://${module.gke.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    host  = "https://${module.gke.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}

# Local variables
locals {
  environment = "prod"
  common_labels = {
    environment = local.environment
    managed_by  = "terraform"
    project     = var.name_prefix
  }
  
  cluster_name = "${var.name_prefix}-gke-${local.environment}"
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  project_id      = var.project_id
  vpc_name        = "${var.name_prefix}-vpc"
  vpc_description = "VPC for ${var.name_prefix} ${local.environment} GKE cluster"
  routing_mode    = "REGIONAL"
  
  subnets = {
    "${var.name_prefix}-gke-subnet" = {
      ip_cidr_range    = "10.10.0.0/24"
      region           = var.region
      description      = "GKE nodes subnet for ${local.environment}"
      enable_flow_logs = var.enable_flow_logs
      secondary_ip_ranges = [
        {
          range_name    = "gke-pods"
          ip_cidr_range = "10.20.0.0/16"
        },
        {
          range_name    = "gke-services"
          ip_cidr_range = "10.30.0.0/16"
        }
      ]
    }
  }
  
  create_nat_gateway = true
  nat_region        = var.region
}

# Security Module
module "security" {
  source = "../../modules/security"
  
  project_id   = var.project_id
  network_name = module.networking.vpc_name
  target_tags  = ["gke-node"]
  
  ssh_source_ranges   = var.allowed_ssh_ips
  rdp_source_ranges   = []
  winrm_source_ranges = []
  internal_ranges     = ["10.0.0.0/8"]
  
  custom_firewall_rules = {
    allow-gke-webhooks = {
      description = "Allow GKE webhook access"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["10.10.0.0/24"]
      target_tags = ["gke-node"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["8443", "9443", "15017"]
        }
      ]
    }
    
    allow-nodeport-services = {
      description = "Allow NodePort services"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["0.0.0.0/0"]
      target_tags = ["gke-node"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["30000-32767"]
        }
      ]
    }
  }
}

# Container Registry Module
module "registry" {
  source = "../../modules/registry"
  
  project_id     = var.project_id
  location       = var.registry_location
  repository_id  = "${var.name_prefix}-registry"
  description    = "Container registry for ${var.name_prefix} ${local.environment}"
  
  labels = local.common_labels
}

# GKE Module
module "gke" {
  source = "../../modules/gke"
  
  project_id     = var.project_id
  name_prefix    = var.name_prefix
  cluster_name   = local.cluster_name
  location       = var.cluster_location
  region         = var.region
  
  # Network configuration
  network                = module.networking.vpc_name
  subnetwork            = module.networking.subnet_self_links["${var.name_prefix}-gke-subnet"]
  pods_range_name       = "gke-pods"
  services_range_name   = "gke-services"
  
  # Master configuration
  master_ipv4_cidr_block = "172.16.0.0/28"
  master_authorized_networks = var.master_authorized_networks
  
  # Node pool configuration
  node_pools = {
    primary = {
      name               = "primary-pool"
      machine_type       = "e2-standard-4"
      min_count         = var.min_node_count
      max_count         = var.max_node_count
      initial_node_count = var.initial_node_count
      disk_size_gb      = 50  # Changed from 100 to 50
      disk_type         = "pd-ssd"
      preemptible       = false
      spot              = false
      
      node_config = {
        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform",
          "https://www.googleapis.com/auth/devstorage.read_only",
          "https://www.googleapis.com/auth/logging.write",
          "https://www.googleapis.com/auth/monitoring",
        ]
        
        labels = merge(local.common_labels, {
          role = "primary"
        })
        
        metadata = {
          disable-legacy-endpoints = "true"
        }
        
        tags = []
      }
    }
    
    spot = {
      name               = "spot-pool"
      machine_type       = "e2-standard-2"
      min_count         = 0
      max_count         = 10
      initial_node_count = 0  # Changed from 2 to 0
      disk_size_gb      = 50
      disk_type         = "pd-standard"
      preemptible       = false
      spot              = true
      
      node_config = {
        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform",
          "https://www.googleapis.com/auth/devstorage.read_only",
          "https://www.googleapis.com/auth/logging.write",
          "https://www.googleapis.com/auth/monitoring",
        ]
        
        labels = merge(local.common_labels, {
          role = "spot"
        })
        
        metadata = {
          disable-legacy-endpoints = "true"
        }
        
        tags = []
        
        taints = [
          {
            key    = "spot"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        ]
      }
    }
  }
  
  # Cluster features
  enable_network_policy     = true
  enable_shielded_nodes    = true
  enable_workload_identity = true
  
  # Addons
  horizontal_pod_autoscaling = true
  http_load_balancing       = true
  network_policy_config     = true
  dns_cache_config         = true
  
  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  
  labels = local.common_labels
  
  # Ensure APIs are enabled before creating GKE cluster
  depends_on = [time_sleep.wait_for_apis]
}

# Kubernetes Addons Module
module "k8s_addons" {
  source = "../../modules/k8s-addons"
  
  cluster_name     = module.gke.cluster_name
  cluster_endpoint = module.gke.endpoint
  project_id       = var.project_id
  region          = var.region
  
  # Install core addons
  install_nginx_ingress     = true
  install_cert_manager      = true
  install_external_dns      = true
  install_cluster_autoscaler = false  # Disable for now due to conflicts
  install_metrics_server    = false   # Already installed by GKE
  install_prometheus        = var.install_prometheus
  install_grafana           = var.install_grafana
  install_jaeger            = var.install_jaeger
  install_argocd            = var.install_argocd
  
  # DNS configuration
  dns_zone_name = var.dns_zone_name
  domain_name   = var.domain_name
  
  # Monitoring configuration
  prometheus_namespace = "monitoring"
  grafana_namespace   = "monitoring"
  
  # ArgoCD configuration
  argocd_namespace = "argocd"
  
  depends_on = [module.gke]
}

# Service Accounts and IAM
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.name_prefix}-gke-sa"
  display_name = "GKE Service Account for ${var.name_prefix}"
  description  = "Service account for GKE cluster nodes"
}

resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/container.nodeServiceAccount",
    "roles/storage.objectViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}