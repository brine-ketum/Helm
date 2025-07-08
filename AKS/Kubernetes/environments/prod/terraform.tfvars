# environments/prod/terraform.tfvars

# Project Configuration
project_id = "poc-project-463913"
region     = "us-west2"
name_prefix = "brinek"

# Cluster Configuration
cluster_location    = "us-west2-a"  # Changed to zonal cluster for exact node count
min_node_count     = 1
max_node_count     = 10
initial_node_count = 2  # This will create exactly 2 nodes in a zonal cluster

# Network Security
allowed_ssh_ips = ["40.143.44.44/32"]  # Replace with your actual IP

# Master authorized networks (restrict API server access)
master_authorized_networks = [
  {
    cidr_block   = "40.143.44.44/32"  # Replace with your actual IP
    display_name = "Admin Access"
  },
  {
    cidr_block   = "10.0.0.0/8"
    display_name = "VPC Internal"
  }
]

# Registry Configuration
registry_location = "us-west2"

# DNS Configuration (optional - set if you have a domain)
dns_zone_name = ""  # e.g., "brinek-zone"
domain_name   = ""  # e.g., "brinek.example.com"

# Addon Configuration
install_prometheus = true
install_grafana    = true
install_jaeger     = false  # Set to true if you need distributed tracing
install_argocd     = true   # GitOps deployment tool

# Network Configuration
enable_flow_logs = true

# Additional Labels
additional_labels = {
  cost-center = "engineering"
  project     = "poc"
  team        = "cloudlens"
}