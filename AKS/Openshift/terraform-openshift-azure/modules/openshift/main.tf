# modules/openshift/main.tf

# Random password for kubeadmin if not provided
resource "random_password" "kubeadmin" {
  length  = 14
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Azure Red Hat OpenShift Cluster
resource "azurerm_redhat_openshift_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  
  cluster_profile {
    domain       = var.domain
    version      = var.openshift_version
    pull_secret  = var.pull_secret
    
    # Resource group for cluster resources (managed by ARO)
    resource_group_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.cluster_name}-cluster-rg"
  }
  
  network_profile {
    pod_cidr     = var.pod_cidr
    service_cidr = var.service_cidr
  }
  
  main_profile {
    vm_size   = var.master_vm_size
    subnet_id = var.master_subnet_id
  }
  
  worker_profile {
    vm_size    = var.worker_vm_size
    disk_size_gb = var.worker_vm_disk_size_gb
    subnet_id  = var.worker_subnet_id
    node_count = var.worker_node_count
  }
  
  api_server_profile {
    visibility = var.api_server_visibility
  }

  ingress_profile {
    visibility = var.ingress_visibility
  }
  
  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }
  
  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      cluster_profile[0].pull_secret,
      service_principal[0].client_secret
    ]
  }
}

# Data source for subscription
data "azurerm_subscription" "current" {}

# Wait for cluster to be ready
resource "time_sleep" "wait_for_cluster" {
  depends_on = [azurerm_redhat_openshift_cluster.main]
  
  create_duration = "5m"
}

# Get cluster credentials (Note: This is a workaround as ARO doesn't expose credentials directly)
data "external" "cluster_credentials" {
  depends_on = [time_sleep.wait_for_cluster]
  
  program = ["bash", "-c", <<-EOT
    # Get cluster credentials using Azure CLI
    CREDS=$(az aro list-credentials \
      --name ${var.cluster_name} \
      --resource-group ${var.resource_group_name} \
      --query '{username: kubeadminUsername, password: kubeadminPassword}' \
      -o json 2>/dev/null || echo '{}')
    
    if [ "$CREDS" = "{}" ]; then
      echo '{"username": "kubeadmin", "password": "pending"}'
    else
      echo "$CREDS"
    fi
  EOT
  ]
}