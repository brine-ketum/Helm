# environments/prod/backend.tf

terraform {
  backend "gcs" {
    bucket = "terraform-state-brinek-prod"
    prefix = "terraform/state/prod/gke"
  }
}