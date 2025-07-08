# environments/prod/backend.tf

terraform {
  backend "gcs" {
    bucket = "terraform-state-brinek-prod"  # Replace with your bucket name
    prefix = "terraform/state/prod"
  }
}