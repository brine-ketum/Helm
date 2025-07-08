# Production-Ready GKE Cluster Deployment Guide

## 🚀 Overview

This Terraform configuration deploys a production-ready Google Kubernetes Engine (GKE) cluster with:

- **GKE Cluster**: Regional cluster with auto-scaling node pools
- **Container Registry**: Google Artifact Registry for storing container images
- **Networking**: VPC with private subnets and Cloud NAT
- **Security**: Firewall rules and IAM configurations
- **Monitoring**: Prometheus, Grafana, and alerting
- **Ingress**: NGINX Ingress Controller with SSL termination
- **GitOps**: ArgoCD for application deployment
- **DNS**: External DNS for automatic DNS management
- **Autoscaling**: Cluster autoscaler and HPA

## 📋 Prerequisites

### 1. Install Required Tools

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install kubectl
gcloud components install kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 2. Set Up GCP Authentication

```bash
# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project poc-project-463913

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable dns.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### 3. Create GCS Bucket for Terraform State

```bash
# Create bucket for Terraform state
gsutil mb -p poc-project-463913 -c STANDARD -l us-west2 gs://terraform-state-brinek-prod

# Enable versioning
gsutil versioning set on gs://terraform-state-brinek-prod
```

## 🔧 Configuration

### 1. Update terraform.tfvars

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# Project Configuration
project_id = "poc-project-463913"
region     = "us-west2"
name_prefix = "brinek"

# Get your public IP
# YOUR_IP=$(curl -s ifconfig.me)
allowed_ssh_ips = ["YOUR_IP/32"]

master_authorized_networks = [
  {
    cidr_block   = "YOUR_IP/32"
    display_name = "Admin Access"
  }
]

# Optional: Configure domain for ingress
domain_name = "your-domain.com"  # Set if you have a domain
dns_zone_name = "your-zone-name" # Set if you have a Cloud DNS zone
```

### 2. Initialize Terraform

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## 🎯 Deployment Steps

### Step 1: Deploy Infrastructure

```bash
cd environments/prod
terraform apply
```

This will create:
- VPC network with subnets
- GKE cluster with node pools
- Artifact Registry
- Firewall rules
- IAM service accounts

### Step 2: Configure kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials brinek-gke-prod --region us-west2 --project poc-project-463913

# Verify cluster access
kubectl get nodes
kubectl get namespaces
```

### Step 3: Configure Docker for Registry

```bash
# Configure Docker authentication
gcloud auth configure-docker us-west2-docker.pkg.dev

# Test registry access
docker pull hello-world
docker tag hello-world us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/hello-world:latest
docker push us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/hello-world:latest
```

## 📊 Accessing Services

### Get Service URLs

```bash
# Get all service URLs
terraform output access_urls

# Get specific service information
kubectl get svc -A
kubectl get ingress -A
```

### Access Methods

#### 1. **Grafana Dashboard**
```bash
# If domain configured:
# https://grafana.your-domain.com

# If no domain (port-forward):
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Access: http://localhost:3000
# Default: admin/admin (change in terraform.tfvars)
```

#### 2. **


# Enterprise Multi-Environment GKE Infrastructure

## 🏗️ Complete Project Structure

```
📁 enterprise-gke-platform/
├── 📄 README.md
├── 📄 DEPLOYMENT_GUIDE.md
├── 🔧 Makefile                          # Multi-environment automation
├── 🔧 setup-all-environments.sh         # Complete setup script
├── 📄 .gitignore
├── 📄 .terraform-version
│
├── 📁 global/                           # Global shared resources
│   ├── 📁 foundation/                   # Project setup, APIs, IAM
│   │   ├── 📄 main.tf
│   │   ├── 📄 variables.tf
│   │   ├── 📄 outputs.tf
│   │   ├── 📄 terraform.tfvars
│   │   └── 📄 backend.tf
│   │
│   ├── 📁 registry/                     # Global container registry
│   │   ├── 📄 main.tf
│   │   ├── 📄 variables.tf
│   │   ├── 📄 outputs.tf
│   │   ├── 📄 terraform.tfvars
│   │   └── 📄 backend.tf
│   │
│   └── 📁 dns/                          # Global DNS zones
│       ├── 📄 main.tf
│       ├── 📄 variables.tf
│       ├── 📄 outputs.tf
│       ├── 📄 terraform.tfvars
│       └── 📄 backend.tf
│
├── 📁 environments/                     # Environment-specific deployments
│   ├── 📁 dev/                          # Development environment
│   │   ├── 📁 gke/
│   │   │   ├── 📄 main.tf               # Complete GKE setup
│   │   │   ├── 📄 variables.tf
│   │   │   ├── 📄 outputs.tf
│   │   │   ├── 📄 terraform.tfvars
│   │   │   └── 📄 backend.tf
│   │   │
│   │   └── 📁 addons/
│   │       ├── 📄 main.tf               # Kubernetes addons
│   │       ├── 📄 variables.tf
│   │       ├── 📄 outputs.tf
│   │       ├── 📄 terraform.tfvars
│   │       └── 📄 backend.tf
│   │
│   ├── 📁 staging/                      # Staging environment
│   │   ├── 📁 gke/
│   │   └── 📁 addons/
│   │
│   └── 📁 prod/                         # Production environment
│       ├── 📁 gke/
│       └── 📁 addons/
│
├── 📁 modules/                          # Reusable Terraform modules
│   ├── 📁 foundation/                   # Foundation setup
│   ├── 📁 networking/                   # VPC and networking
│   ├── 📁 security/                     # Security and firewall
│   ├── 📁 gke/                          # GKE cluster
│   ├── 📁 registry/                     # Container registry
│   ├── 📁 k8s-addons/                   # Kubernetes addons
│   ├── 📁 monitoring/                   # Observability stack
│   └── 📁 backup/                       # Backup and DR
│
├── 📁 config/                           # Configuration files
│   ├── 📁 environments/
│   │   ├── 📄 dev.yaml
│   │   ├── 📄 staging.yaml
│   │   └── 📄 prod.yaml
│   │
│   └── 📁 common/
│       ├── 📄 locals.tf
│       └── 📄 variables.tf
│
└── 📁 scripts/                          # Automation scripts
    ├── 🔧 deploy-environment.sh
    ├── 🔧 setup-kubectl.sh
    ├── 🔧 monitoring.sh
    └── 🔧 backup.sh
```

## 🌍 Environment Architecture

### **Development Environment**
- **Cluster**: Single-zone, minimal resources
- **Node Pools**: 1 primary pool (e2-medium)
- **Addons**: Basic monitoring, ingress
- **Purpose**: Development and testing

### **Staging Environment** 
- **Cluster**: Multi-zone, production-like
- **Node Pools**: 2 pools (primary + spot)
- **Addons**: Full monitoring, security scanning
- **Purpose**: Pre-production validation

### **Production Environment**
- **Cluster**: Regional, high availability
- **Node Pools**: 3 pools (system + primary + compute)
- **Addons**: Complete observability stack
- **Purpose**: Production workloads