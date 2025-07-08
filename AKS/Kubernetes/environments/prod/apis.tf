# environments/prod/apis.tf

# Enable required Google Cloud APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",              # Compute Engine API
    "container.googleapis.com",            # Kubernetes Engine API
    "artifactregistry.googleapis.com",     # Artifact Registry API
    "containerscanning.googleapis.com",    # Container Scanning API
    "secretmanager.googleapis.com",        # Secret Manager API
    "cloudresourcemanager.googleapis.com", # Cloud Resource Manager API
    "iam.googleapis.com",                  # IAM API
    "logging.googleapis.com",              # Cloud Logging API
    "monitoring.googleapis.com",           # Cloud Monitoring API
  ])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# Add a delay after enabling APIs to ensure they're fully propagated
resource "time_sleep" "wait_for_apis" {
  depends_on = [google_project_service.required_apis]
  
  create_duration = "60s"
}