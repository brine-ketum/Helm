# modules/openshift-workers/main.tf

# Store values in locals for use in destroy provisioner
locals {
  cluster_name            = var.cluster_name
  resource_group_name     = var.resource_group_name
  worker_profile_name     = var.worker_profile_name
  worker_vm_size          = var.worker_vm_size
  worker_vm_disk_size_gb  = var.worker_vm_disk_size_gb
  worker_subnet_id        = var.worker_subnet_id
  worker_node_count       = var.worker_node_count
}

# Additional Worker Profile for existing OpenShift cluster
resource "null_resource" "additional_worker_profile" {
  triggers = {
    cluster_name        = local.cluster_name
    resource_group_name = local.resource_group_name
    worker_profile_name = local.worker_profile_name
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      az aro update \
        --name ${local.cluster_name} \
        --resource-group ${local.resource_group_name} \
        --worker-profile \
          name=${local.worker_profile_name} \
          vm-size=${local.worker_vm_size} \
          disk-size=${local.worker_vm_disk_size_gb} \
          subnet-id=${local.worker_subnet_id} \
          count=${local.worker_node_count}
    EOT
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Scale down to 0 before removing
      az aro update \
        --name ${self.triggers.cluster_name} \
        --resource-group ${self.triggers.resource_group_name} \
        --worker-profile \
          name=${self.triggers.worker_profile_name} \
          count=0
    EOT
  }
}