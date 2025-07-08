# 🚀 Azure Red Hat OpenShift (ARO) Cluster Deployment with Terraform

Complete guide for deploying a production-ready OpenShift cluster on Azure using Terraform, including all fixes and configurations that made it work.

![OpenShift](https://img.shields.io/badge/OpenShift-4.17.27-red)
![Azure](https://img.shields.io/badge/Azure-ARO-blue)
![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple)
![Status](https://img.shields.io/badge/Status-Production-green)

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Critical Fixes That Made It Work](#critical-fixes-that-made-it-work)
- [Project Structure](#project-structure)
- [Step-by-Step Deployment Guide](#step-by-step-deployment-guide)
- [Configuration Details](#configuration-details)
- [Troubleshooting](#troubleshooting)
- [Post-Deployment](#post-deployment)
- [Cleanup](#cleanup)

## 🌟 Overview

This project deploys a production-ready Azure Red Hat OpenShift (ARO) cluster with:
- **6 Nodes Total**: 3 Master nodes + 3 Worker nodes
- **High Availability**: Multi-zone deployment across 3 availability zones
- **Fully Managed**: Azure manages the control plane
- **Integrated Services**: Container Registry, Key Vault, Storage, Monitoring
- **Network Security**: Private subnets, NSGs, and service endpoints

### Deployed Resources
- ✅ Azure Red Hat OpenShift Cluster (ARO)
- ✅ Virtual Network with Master/Worker Subnets
- ✅ Azure Container Registry (Premium)
- ✅ Key Vault for Secrets
- ✅ Log Analytics Workspace
- ✅ Storage Account for Registry
- ✅ Network Security Groups
- ✅ Service Principal with proper permissions

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Subscription                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Resource Group: keysight-prod-rg          │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │                                                          │   │
│  │  ┌─────────────── Virtual Network ──────────────┐       │   │
│  │  │          VNet: keysight-vnet (10.0.0.0/16)   │       │   │
│  │  │                                               │       │   │
│  │  │  ┌──────── Master Subnet ────────┐           │       │   │
│  │  │  │    10.0.0.0/23 (512 IPs)      │           │       │   │
│  │  │  │  ┌────┐  ┌────┐  ┌────┐      │           │       │   │
│  │  │  │  │ M1 │  │ M2 │  │ M3 │      │           │       │   │
│  │  │  │  └────┘  └────┘  └────┘      │           │       │   │
│  │  │  │   Zone1   Zone2   Zone3       │           │       │   │
│  │  │  └───────────────────────────────┘           │       │   │
│  │  │                                               │       │   │
│  │  │  ┌──────── Worker Subnet ────────┐           │       │   │
│  │  │  │    10.0.2.0/23 (512 IPs)      │           │       │   │
│  │  │  │  ┌────┐  ┌────┐  ┌────┐      │           │       │   │
│  │  │  │  │ W1 │  │ W2 │  │ W3 │      │           │       │   │
│  │  │  │  └────┘  └────┘  └────┘      │           │       │   │
│  │  │  │   Zone1   Zone2   Zone3       │           │       │   │
│  │  │  └───────────────────────────────┘           │       │   │
│  │  └───────────────────────────────────────────────┘       │   │
│  │                                                          │   │
│  │  ┌─────────────── Supporting Services ──────────────┐    │   │
│  │  │                                                  │    │   │
│  │  │  🔐 Key Vault: keysight-prod-kvXXXX            │    │   │
│  │  │  📦 ACR: keysightregistryXXXX (Premium)        │    │   │
│  │  │  💾 Storage: keysightprodregXXXX               │    │   │
│  │  │  📊 Log Analytics: keysight-prod-logs          │    │   │
│  │  │  🔒 NSG: keysight-nsg                          │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

### 1. **Azure CLI & Login**
```bash
# Install Azure CLI
brew install azure-cli  # macOS
# or
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Linux

# Login to Azure
az login
az account show

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. **Terraform**
```bash
# Install Terraform
brew install terraform  # macOS

# Verify version (need 1.0+)
terraform version
```

### 3. **OpenShift CLI**
```bash
# Install oc CLI
brew install openshift-cli

# Verify
oc version
```

### 4. **Red Hat Pull Secret**
Get from: https://console.redhat.com/openshift/install/azure/aro-provisioned
Save as pull-secret.txt

### 5. **Azure Subscription Requirements**
- Azure subscription with sufficient quota
- Minimum required vCPUs: 44 for StandardDSv3Family

## 🔧 Critical Fixes That Made It Work

### 1. **Azure Quota Issue** ⚡
**Problem**: "Resource quota of standardDSv3Family exceeded. Maximum allowed: 10, Current in use: 2, Additional requested: 44"

**Solution**: Request quota increase
```bash
# Check current quota
az vm list-usage --location "westus2" --query "[?name.value=='standardDSv3Family']" -o table

# Request increase via Azure Portal
# Portal → Subscriptions → Usage + quotas → Request Increase
# Family: StandardDSv3Family
# New limit: 50+
```

### 2. **Service Principal Issues** 🔑
**Problem**: "PrincipalNotFound" error when assigning roles

**Solution**: Add principal_type and time delay
```hcl
resource "azurerm_role_assignment" "example" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp.object_id
  principal_type       = "ServicePrincipal"  # CRITICAL!
}

# Add delay for AD replication
resource "time_sleep" "wait_for_sp_propagation" {
  depends_on      = [azuread_service_principal.sp]
  create_duration = "60s"
}
```

### 3. **ARO Resource Provider Permissions** 🛡️
**Problem**: "The resource provider service principal does not have Network Contributor role on vnet"

**Solution**: Grant permissions to ARO service principal
```bash
# Grant Network Contributor to ARO SP
az role assignment create \
  --assignee "f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875" \
  --role "Network Contributor" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.Network/virtualNetworks/VNET_NAME"
```

### 4. **Terraform Import Issues** 📦
**Problem**: "A resource with the ID already exists"

**Solution**: Import existing resources
```bash
terraform import module.openshift.azurerm_redhat_openshift_cluster.main /subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.RedHatOpenShift/openShiftClusters/CLUSTER_NAME
```

## 📁 Project Structure

```
terraform-openshift-azure/
├── environments/
│   └── prod/
│       ├── main.tf                 # Main configuration
│       ├── variables.tf            # Variable definitions
│       ├── outputs.tf              # Output values
│       ├── terraform.tfvars        # Environment-specific values
│       └── backend.tf              # State backend config
├── modules/
│   ├── networking/                 # VNet, Subnets, NSGs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── openshift/                  # ARO cluster
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── registry/                   # Azure Container Registry
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/                   # NSGs and rules
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── service-principal/          # Service Principal
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md
```

## 📝 Step-by-Step Deployment Guide

### Step 1: Clone and Prepare
```bash
# Clone the repository
git clone <your-repo>
cd terraform-openshift-azure/environments/prod

# Copy example files
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Configure terraform.tfvars
```hcl
# environments/prod/terraform.tfvars
subscription_id     = "YOUR_SUBSCRIPTION_ID"
location           = "westus2"
name_prefix        = "keysight"

# OpenShift Configuration
openshift_version  = "4.17.27"
openshift_pull_secret = file("./pull-secret.txt")

# VM Sizes
master_vm_size     = "Standard_D8s_v3"  # 8 vCPUs x 3 = 24 vCPUs
worker_vm_size     = "Standard_D4s_v3"  # 4 vCPUs x 3 = 12 vCPUs
worker_node_count  = 3

# Network
api_server_visibility = "Public"
ingress_visibility    = "Public"
```

### Step 3: Initialize Terraform
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan
```

### Step 4: Pre-deployment Checks
```bash
# Check Azure quota
az vm list-usage --location "westus2" --query "[?name.value=='standardDSv3Family']" -o table

# Ensure quota is sufficient (need 44+ vCPUs)
```

### Step 5: Grant ARO Permissions
```bash
# This is CRITICAL - grant permissions before deployment
az ad sp list --display-name "Azure Red Hat OpenShift RP" --query "[0].appId" -o tsv

# Use the app ID (f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875) to grant permissions
# This will be done by Terraform if configured properly
```

### Step 6: Deploy Infrastructure
```bash
# Deploy in stages for better control

# 1. Deploy base infrastructure first
terraform apply -target=azurerm_resource_group.main -auto-approve
terraform apply -target=module.networking -auto-approve

# 2. Deploy service principal and permissions
terraform apply -target=module.service_principal -auto-approve
terraform apply -target=azurerm_role_assignment.openshift_sp_network_contributor -auto-approve

# 3. Grant ARO permissions (if not in Terraform)
az role assignment create \
  --assignee "f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875" \
  --role "Network Contributor" \
  --scope "$(terraform output -raw vnet_id)"

# 4. Deploy supporting services
terraform apply -target=module.registry -auto-approve
terraform apply -target=azurerm_key_vault.main -auto-approve

# 5. Finally, deploy OpenShift (takes 30-45 minutes)
terraform apply -auto-approve
```

### Step 7: Monitor Deployment
```bash
# Watch cluster status (in another terminal)
while true; do
  clear
  echo "=== ARO Cluster Status ==="
  az aro show --name keysight-aro-prod --resource-group keysight-prod-rg \
    --query '{State:provisioningState, URL:consoleProfile.url}' -o table
  sleep 30
done
```

### Step 8: Get Credentials
```bash
# Get cluster credentials
az aro list-credentials \
  --name keysight-aro-prod \
  --resource-group keysight-prod-rg

# Get console URL
terraform output openshift_console_url

# Login via CLI
API_URL=$(terraform output -raw openshift_api_server_url)
PASSWORD=$(terraform output -raw openshift_console_password)
oc login $API_URL -u kubeadmin -p $PASSWORD
```

## ⚙️ Configuration Details

### main.tf Key Components
```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-${local.environment}-rg"
  location = var.location
  tags     = local.common_tags
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  vnet_address_space = ["10.0.0.0/16"]
  subnets = {
    "${local.master_subnet_name}" = {
      address_prefixes = ["10.0.0.0/23"]  # /23 required for masters
      service_endpoints = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
    }
    "${local.worker_subnet_name}" = {
      address_prefixes = ["10.0.2.0/23"]  # /23 required for workers
    }
  }
}

# Critical: ARO Service Principal Permissions
data "azuread_service_principal" "aro" {
  client_id = "f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875"
}

resource "azurerm_role_assignment" "aro_vnet_contributor" {
  scope                = module.networking.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = data.azuread_service_principal.aro.object_id
  principal_type       = "ServicePrincipal"
}

# OpenShift Module
module "openshift" {
  source = "../../modules/openshift"
  
  cluster_name      = local.cluster_name
  openshift_version = var.openshift_version
  pull_secret       = var.openshift_pull_secret
  
  # Network configuration
  vnet_id          = module.networking.vnet_id
  master_subnet_id = module.networking.subnet_ids[local.master_subnet_name]
  worker_subnet_id = module.networking.subnet_ids[local.worker_subnet_name]
  
  # VM configuration
  master_vm_size         = var.master_vm_size
  worker_vm_size         = var.worker_vm_size
  worker_node_count      = var.worker_node_count
  
  depends_on = [
    azurerm_role_assignment.aro_vnet_contributor,
    azurerm_role_assignment.aro_rg_contributor
  ]
}
```

### Outputs Configuration
```hcl
output "openshift_console_url" {
  value = module.openshift.console_url
}

output "openshift_api_server_url" {
  value = module.openshift.api_server_url
}

output "openshift_console_password" {
  value     = module.openshift.console_password
  sensitive = true
}
```

## 🔍 Troubleshooting

### Failed Cluster Deployment
```bash
# Check cluster status
az aro show --name keysight-aro-prod --resource-group keysight-prod-rg

# Check detailed error
az aro show --name keysight-aro-prod --resource-group keysight-prod-rg \
  --query 'properties.provisioningStateMessage' -o tsv

# Delete failed cluster and retry
az aro delete --name keysight-aro-prod --resource-group keysight-prod-rg --yes
terraform apply
```

### Service Principal Issues
```bash
# List service principal
az ad sp list --display-name "keysight-sp" --query "[0]"

# Check role assignments
az role assignment list --assignee <SP_OBJECT_ID> --output table

# Recreate if needed
terraform destroy -target=module.service_principal
terraform apply -target=module.service_principal
```

### Network Issues
```bash
# Verify subnets
az network vnet subnet list --resource-group keysight-prod-rg --vnet-name keysight-vnet -o table

# Check NSG rules
az network nsg rule list --resource-group keysight-prod-rg --nsg-name keysight-nsg -o table
```

### Quota Issues
```bash
# Check all quotas
az vm list-usage --location "westus2" -o table

# Request increase
# Go to: Portal → Subscriptions → Usage + quotas
```

## 🚀 Post-Deployment

### 1. Access OpenShift Console
```bash
# Get console URL and credentials
echo "Console URL: $(terraform output -raw openshift_console_url)"
echo "Username: kubeadmin"
echo "Password: $(terraform output -raw openshift_console_password)"

# Open console
open $(terraform output -raw openshift_console_url)
```

### 2. Configure kubectl/oc
```bash
# Login via CLI
oc login $(terraform output -raw openshift_api_server_url) \
  -u kubeadmin \
  -p $(terraform output -raw openshift_console_password)

# Verify nodes
oc get nodes

# Check cluster version
oc get clusterversion
```

### 3. Configure Container Registry
```bash
# Get ACR credentials
ACR_NAME=$(terraform output -raw registry_login_server | cut -d'.' -f1)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

# Create secret in OpenShift
oc create secret docker-registry acr-secret \
  --docker-server=$(terraform output -raw registry_login_server) \
  --docker-username=$ACR_NAME \
  --docker-password=$ACR_PASSWORD
```

### 4. Deploy Sample Application
```bash
# Create new project
oc new-project demo

# Deploy sample app
oc new-app httpd~https://github.com/sclorg/httpd-ex

# Expose route
oc expose svc/httpd-ex

# Get route
oc get route
```

## 🧹 Cleanup

```bash
# Delete OpenShift cluster (takes 10-15 minutes)
terraform destroy -target=module.openshift -auto-approve

# Delete all resources
terraform destroy -auto-approve

# Verify cleanup
az resource list --resource-group keysight-prod-rg -o table
```

## 💰 Cost Optimization

### Estimated Monthly Costs (USD)
- Master Nodes (3x D8s_v3): ~$1,050
- Worker Nodes (3x D4s_v3): ~$525  
- ARO Service Fee: ~$600
- Supporting Services: ~$200
- **Total: ~$2,375/month**

### Cost Saving Tips
1. Use smaller VM sizes for dev/test
2. Scale worker nodes based on workload
3. Stop cluster when not in use (not recommended for production)
4. Use Azure Reserved Instances for long-term deployments

## 🔒 Security Best Practices

1. **Network Security**
   - Private master/worker subnets
   - NSGs with strict rules
   - Service endpoints for Azure services

2. **Access Control**
   - API server IP whitelisting
   - Azure AD integration
   - RBAC policies

3. **Secrets Management**
   - Store pull secret in Key Vault
   - Use managed identities where possible
   - Rotate service principal credentials

4. **Monitoring**
   - Enable Azure Monitor for containers
   - Configure Log Analytics
   - Set up alerts for critical events

## 📚 Additional Resources

- [Azure Red Hat OpenShift Documentation](https://docs.microsoft.com/en-us/azure/openshift/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [ARO Support](https://access.redhat.com/products/azure-red-hat-openshift)

## 🤝 Support

- **Azure Support**: Create support ticket in Azure Portal
- **Red Hat Support**: Access via Red Hat Customer Portal
- **Community**: [OpenShift Commons](https://commons.openshift.org/)

---

**Deployed with using Terraform and Azure**