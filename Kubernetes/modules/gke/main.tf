# modules/gke/main.tf

# Service Account for GKE nodes
resource "google_service_account" "default" {
  count = var.create_service_account ? 1 : 0
  
  account_id   = "${var.name_prefix}-gke-node-sa"
  display_name = "GKE Node Service Account"
  description  = "Service account for GKE cluster nodes"
}

resource "google_project_iam_member" "default" {
  for_each = var.create_service_account ? toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ]) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.default[0].email}"
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location
  
  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Cluster configuration
  min_master_version = var.kubernetes_version
  
  deletion_protection = false
  # Workload Identity
  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }
  
  # IP allocation policy for VPC-native networking
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    
    master_global_access_config {
      enabled = var.master_global_access
    }
  }
  
  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }
  
  # Network policy
  dynamic "network_policy" {
    for_each = var.enable_network_policy ? [1] : []
    content {
      enabled  = true
      provider = "CALICO"
    }
  }
  
  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = !var.http_load_balancing
    }
    
    horizontal_pod_autoscaling {
      disabled = !var.horizontal_pod_autoscaling
    }
    
    network_policy_config {
      disabled = !var.network_policy_config
    }
    
    dns_cache_config {
      enabled = var.dns_cache_config
    }
    
    gcp_filestore_csi_driver_config {
      enabled = var.filestore_csi_driver
    }
    
    gce_persistent_disk_csi_driver_config {
      enabled = var.gce_pd_csi_driver
    }
  }
  
  # Cluster autoscaling
  dynamic "cluster_autoscaling" {
    for_each = var.cluster_autoscaling ? [1] : []
    content {
      enabled = true
      resource_limits {
        resource_type = "cpu"
        minimum       = var.cluster_autoscaling_cpu_min
        maximum       = var.cluster_autoscaling_cpu_max
      }
      resource_limits {
        resource_type = "memory"
        minimum       = var.cluster_autoscaling_memory_min
        maximum       = var.cluster_autoscaling_memory_max
      }
      
      auto_provisioning_defaults {
        service_account = var.create_service_account ? google_service_account.default[0].email : var.node_service_account
        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform"
        ]
        
        management {
          auto_repair  = true
          auto_upgrade = true
        }
        
        shielded_instance_config {
          enable_secure_boot          = true
          enable_integrity_monitoring = true
        }
      }
    }
  }
  
  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = var.maintenance_start_time
      end_time   = var.maintenance_end_time
      recurrence = var.maintenance_recurrence
    }
  }
  
  # Logging and monitoring
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service
  
  # Resource labels
  resource_labels = var.labels
  
  timeouts {
    create = "30m"
    update = "40m"
    delete = "40m"
  }
}

# Node Pools
resource "google_container_node_pool" "pools" {
  for_each = var.node_pools
  
  name       = each.value.name
  location   = google_container_cluster.primary.location
  cluster    = google_container_cluster.primary.name
  
  # Node count configuration
  initial_node_count = lookup(each.value, "initial_node_count", 1)
  
  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [1] : []
    content {
      min_node_count = lookup(each.value, "min_count", 1)
      max_node_count = lookup(each.value, "max_count", 3)
    }
  }
  
  # Management configuration
  management {
    auto_repair  = lookup(each.value, "auto_repair", true)
    auto_upgrade = lookup(each.value, "auto_upgrade", true)
  }
  
  # Upgrade settings
  upgrade_settings {
    max_surge       = lookup(each.value, "max_surge", 1)
    max_unavailable = lookup(each.value, "max_unavailable", 0)
    
    dynamic "blue_green_settings" {
      for_each = lookup(each.value, "enable_blue_green", false) ? [1] : []
      content {
        standard_rollout_policy {
          batch_percentage    = lookup(each.value, "batch_percentage", 100)
          batch_node_count   = lookup(each.value, "batch_node_count", null)
          batch_soak_duration = lookup(each.value, "batch_soak_duration", "0s")
        }
        node_pool_soak_duration = lookup(each.value, "node_pool_soak_duration", "0s")
      }
    }
  }
  
  # Node configuration
  node_config {
    preemptible  = lookup(each.value, "preemptible", false)
    spot         = lookup(each.value, "spot", false)
    machine_type = lookup(each.value, "machine_type", "e2-medium")
    
    # Google service account for the node VMs
    service_account = var.create_service_account ? google_service_account.default[0].email : var.node_service_account
    oauth_scopes = lookup(
      lookup(each.value, "node_config", {}),
      "oauth_scopes",
      [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    )
    
    # Disk configuration
    disk_size_gb = lookup(each.value, "disk_size_gb", 100)
    disk_type    = lookup(each.value, "disk_type", "pd-standard")
    image_type   = lookup(each.value, "image_type", "COS_CONTAINERD")
    
    # Labels and metadata
    labels = merge(
      var.labels,
      lookup(lookup(each.value, "node_config", {}), "labels", {})
    )
    
    metadata = merge(
      {
        disable-legacy-endpoints = "true"
      },
      lookup(lookup(each.value, "node_config", {}), "metadata", {})
    )
    
    # Tags
    tags = concat(
      lookup(lookup(each.value, "node_config", {}), "tags", []),
      ["gke-node", "${var.cluster_name}-node"]
    )
    
    # Taints
    dynamic "taint" {
      for_each = lookup(lookup(each.value, "node_config", {}), "taints", [])
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
    
    # Shielded instance configuration
    dynamic "shielded_instance_config" {
      for_each = var.enable_shielded_nodes ? [1] : []
      content {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
    
    # Workload metadata configuration
    dynamic "workload_metadata_config" {
      for_each = var.enable_workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }
  }
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}