# modules/openshift/outputs.tf

output "cluster_id" {
  description = "The ID of the OpenShift cluster"
  value       = azurerm_redhat_openshift_cluster.main.id
}

output "cluster_name" {
  description = "The name of the OpenShift cluster"
  value       = azurerm_redhat_openshift_cluster.main.name
}

output "console_url" {
  description = "The console URL of the OpenShift cluster"
  value       = azurerm_redhat_openshift_cluster.main.console_url
}

output "api_server_url" {
  description = "The API server URL of the OpenShift cluster"
  value       = azurerm_redhat_openshift_cluster.main.api_server_profile[0].url
}

output "console_username" {
  description = "Username for console access"
  value       = try(data.external.cluster_credentials.result.username, "kubeadmin")
}

output "console_password" {
  description = "Password for console access"
  value       = try(data.external.cluster_credentials.result.password, "Check Azure Portal")
  sensitive   = true
}

output "domain" {
  description = "The domain of the OpenShift cluster"
  value       = azurerm_redhat_openshift_cluster.main.cluster_profile[0].domain
}

output "openshift_version" {
  description = "The OpenShift version"
  value       = azurerm_redhat_openshift_cluster.main.cluster_profile[0].version
}

output "resource_group_id" {
  description = "The resource group ID for cluster resources"
  value       = azurerm_redhat_openshift_cluster.main.cluster_profile[0].resource_group_id
}

output "master_profile" {
  description = "Master node configuration"
  value = {
    vm_size   = azurerm_redhat_openshift_cluster.main.main_profile[0].vm_size
    subnet_id = azurerm_redhat_openshift_cluster.main.main_profile[0].subnet_id
  }
}

output "worker_profiles" {
  description = "Worker node configuration"
  value = {
    default = {
      vm_size      = azurerm_redhat_openshift_cluster.main.worker_profile[0].vm_size
      disk_size_gb = azurerm_redhat_openshift_cluster.main.worker_profile[0].disk_size_gb
      count        = azurerm_redhat_openshift_cluster.main.worker_profile[0].node_count
      subnet_id    = azurerm_redhat_openshift_cluster.main.worker_profile[0].subnet_id
    }
  }
}