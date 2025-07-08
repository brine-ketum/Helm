# GCP to Azure Terraform Migration Guide

## Overview of Changes

This guide summarizes the key changes made when migrating the Terraform infrastructure from Google Cloud Platform (GCP) to Microsoft Azure.

## Provider Changes

### GCP Providers → Azure Providers
```hcl
# GCP
provider "google" {}
provider "google-beta" {}

# Azure
provider "azurerm" {}
provider "azuread" {}
```

## Resource Mapping

### Core Infrastructure

| GCP Resource | Azure Resource | Key Differences |
|--------------|----------------|-----------------|
| `google_project_service` | Built into Azure | APIs are enabled by default in Azure |
| `google_compute_network` | `azurerm_virtual_network` | Azure uses VNets instead of VPCs |
| `google_compute_subnetwork` | `azurerm_subnet` | Azure subnets are simpler, no secondary ranges |
| `google_compute_firewall` | `azurerm_network_security_group` | NSGs use priority-based rules |
| `google_compute_router` | `azurerm_nat_gateway` | Different NAT implementation |

### Kubernetes

| GCP Resource | Azure Resource | Key Differences |
|--------------|----------------|-----------------|
| `google_container_cluster` (GKE) | `azurerm_kubernetes_cluster` (AKS) | Different configuration options |
| `google_container_node_pool` | `azurerm_kubernetes_cluster_node_pool` | Similar concept, different properties |
| Workload Identity | Managed Identity | Azure uses Managed Service Identity |
| Master authorized networks | API server access profile | Similar functionality |

### Container Registry

| GCP Resource | Azure Resource | Key Differences |
|--------------|----------------|-----------------|
| `google_artifact_registry_repository` | `azurerm_container_registry` | ACR is account-level, not repository-level |
| Multiple formats supported | Docker-only by default | ACR focuses on container images |

### Security & Secrets

| GCP Resource | Azure Resource | Key Differences |
|--------------|----------------|-----------------|
| `google_secret_manager_secret` | `azurerm_key_vault_secret` | Key Vault provides broader functionality |
| Service Account + Keys | Service Principal + Managed Identity | Azure prefers managed identities |
| IAM bindings | Role assignments | Different RBAC model |

## Configuration Changes

### 1. Network Configuration

**GCP:**
```hcl
ip_allocation_policy {
  cluster_secondary_range_name  = "gke-pods"
  services_secondary_range_name = "gke-services"
}
```

**Azure:**
```hcl
network_profile {
  network_plugin     = "azure"
  network_policy     = "azure"
  service_cidr       = "10.2.0.0/16"
  dns_service_ip     = "10.2.0.10"
  docker_bridge_cidr = "172.17.0.1/16"
}
```

### 2. Node Pool Configuration

**GCP:**
```hcl
node_config {
  preemptible  = false
  spot         = true
  machine_type = "e2-standard-2"
}
```

**Azure:**
```hcl
priority        = "Spot"
eviction_policy = "Delete"
spot_max_price  = -1
vm_size        = "Standard_D2s_v3"
```

### 3. Authentication

**GCP:**
- Service Accounts with keys
- Workload Identity for pod authentication

**Azure:**
- Managed Identity (preferred)
- Service Principals with passwords
- Azure AD integration for RBAC

### 4. Storage Classes

**GCP:**
- `pd-standard` → `managed-csi`
- `pd-ssd` → `managed-csi-premium`

**Azure:**
- Uses Azure Disk CSI driver
- Default storage classes provided by AKS

## Module Structure Changes

The module structure remains similar, but internal implementations differ:

1. **networking module**: 
   - Added NAT Gateway configuration
   - Simplified subnet configuration (no secondary ranges)

2. **security module**:
   - Uses NSGs instead of firewall rules
   - Priority-based rule system
   - Application Security Groups support

3. **registry module**:
   - Account-level registry vs repository-level
   - Different authentication mechanisms

4. **aks module**:
   - System vs User node pools
   - Built-in autoscaling configuration
   - Azure-specific addons

5. **k8s-addons module**:
   - Azure Key Vault for secrets
   - Azure DNS configuration for external-dns
   - Storage class adjustments

## Environment Variables

### GCP → Azure
```bash
# GCP
export GOOGLE_APPLICATION_CREDENTIALS="path/to/key.json"

# Azure
az login
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```

## Cost Considerations

1. **Spot Instances**: Azure Spot VMs work similarly to GCP Spot VMs
2. **Pricing Model**: Azure charges per minute (GCP per second)
3. **Free Tier**: Different free tier offerings
4. **Reserved Instances**: Azure offers Reserved VM Instances for cost savings

## Migration Steps

1. **Export Data**: Backup any persistent data from GCP
2. **Update DNS**: Prepare to update DNS records
3. **Container Images**: Migrate images from GCR to ACR
4. **Secrets**: Migrate from Secret Manager to Key Vault
5. **Deploy Azure**: Run Terraform to create Azure infrastructure
6. **Migrate Workloads**: Deploy applications to AKS
7. **Update DNS**: Point DNS to new Azure load balancers
8. **Validate**: Ensure all services are running correctly
9. **Cleanup GCP**: Remove GCP resources after validation

## Common Gotchas

1. **Resource Names**: Azure has stricter naming conventions
2. **Region Names**: Different region naming (us-west2 vs westus2)
3. **API Differences**: Some features may not have direct equivalents
4. **RBAC Model**: Azure AD integration works differently than GCP IAM
5. **Storage**: Different storage class names and capabilities

## Validation Commands

```bash
# Verify cluster
az aks show --resource-group brinek-prod-rg --name brinek-aks-prod

# Check node pools
az aks nodepool list --resource-group brinek-prod-rg --cluster-name brinek-aks-prod

# Verify registry
az acr show --name brinekregistry

# Check network
az network vnet show --resource-group brinek-prod-rg --name brinek-vnet
```