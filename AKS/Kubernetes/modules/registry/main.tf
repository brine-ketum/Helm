# modules/registry/main.tf

# Artifact Registry Repository
resource "google_artifact_registry_repository" "registry" {
  location      = var.location
  repository_id = var.repository_id
  description   = var.description
  format        = var.format
  project       = var.project_id
  
  labels = var.labels
  
  # Docker-specific configuration
  dynamic "docker_config" {
    for_each = var.format == "DOCKER" ? [1] : []
    content {
      immutable_tags = var.immutable_tags
    }
  }
  
  # Maven-specific configuration
  dynamic "maven_config" {
    for_each = var.format == "MAVEN" ? [1] : []
    content {
      allow_snapshot_overwrites = var.allow_snapshot_overwrites
      version_policy           = var.maven_version_policy
    }
  }
  
  # Cleanup policies
  dynamic "cleanup_policies" {
    for_each = var.cleanup_policies
    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action
      
      dynamic "condition" {
        for_each = [cleanup_policies.value.condition]
        content {
          tag_state             = lookup(condition.value, "tag_state", null)
          tag_prefixes          = lookup(condition.value, "tag_prefixes", null)
          version_name_prefixes = lookup(condition.value, "version_name_prefixes", null)
          package_name_prefixes = lookup(condition.value, "package_name_prefixes", null)
          older_than           = lookup(condition.value, "older_than", null)
        }
      }
      
      dynamic "most_recent_versions" {
        for_each = lookup(cleanup_policies.value, "most_recent_versions", null) != null ? [cleanup_policies.value.most_recent_versions] : []
        content {
          package_name_prefixes = lookup(most_recent_versions.value, "package_name_prefixes", null)
          keep_count           = lookup(most_recent_versions.value, "keep_count", null)
        }
      }
    }
  }
}

# Service account for pushing images
resource "google_service_account" "push_sa" {
  count = var.create_push_service_account ? 1 : 0
  
  account_id   = "${var.repository_id}-push"
  display_name = "Service account for pushing to ${var.repository_id}"
  project      = var.project_id
}

# Service account key
resource "google_service_account_key" "push_sa_key" {
  count = var.create_push_service_account && var.create_push_service_account_key ? 1 : 0
  
  service_account_id = google_service_account.push_sa[0].name
}

# IAM bindings for readers
resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each = toset(var.reader_members)
  
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = "roles/artifactregistry.reader"
  member     = each.value
}

# IAM bindings for writers
resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each = toset(var.writer_members)
  
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = "roles/artifactregistry.writer"
  member     = each.value
}

# IAM binding for push service account
resource "google_artifact_registry_repository_iam_member" "push_sa_writer" {
  count = var.create_push_service_account ? 1 : 0
  
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.push_sa[0].email}"
}

# IAM bindings for admins
resource "google_artifact_registry_repository_iam_member" "admins" {
  for_each = toset(var.admin_members)
  
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = "roles/artifactregistry.admin"
  member     = each.value
}

# Enable vulnerability scanning (if applicable)
resource "google_project_service" "container_scanning" {
  count = var.enable_vulnerability_scanning ? 1 : 0
  
  project = var.project_id
  service = "containerscanning.googleapis.com"
  
  disable_on_destroy = false
}

# Store service account key in Secret Manager (if created)
resource "google_secret_manager_secret" "push_sa_key" {
  count = var.create_push_service_account && var.create_push_service_account_key ? 1 : 0
  
  secret_id = "${var.repository_id}-push-sa-key"
  project   = var.project_id
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "push_sa_key" {
  count = var.create_push_service_account && var.create_push_service_account_key ? 1 : 0
  
  secret = google_secret_manager_secret.push_sa_key[0].id
  
  secret_data = base64decode(google_service_account_key.push_sa_key[0].private_key)
}