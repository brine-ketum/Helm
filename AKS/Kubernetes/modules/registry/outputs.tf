# modules/registry/outputs.tf

output "registry_id" {
  description = "The ID of the registry"
  value       = google_artifact_registry_repository.registry.id
}

output "registry_name" {
  description = "The name of the registry"
  value       = google_artifact_registry_repository.registry.name
}

output "registry_url" {
  description = "The URL of the registry"
  value       = "${var.location}-${lower(var.format)}.pkg.dev/${var.project_id}/${var.repository_id}"
}

output "registry_location" {
  description = "The location of the registry"
  value       = google_artifact_registry_repository.registry.location
}

output "registry_format" {
  description = "The format of the registry"
  value       = google_artifact_registry_repository.registry.format
}

output "push_service_account_email" {
  description = "Email of the push service account"
  value       = var.create_push_service_account ? google_service_account.push_sa[0].email : null
}

output "push_service_account_key_secret" {
  description = "Secret Manager secret containing the push service account key"
  value       = var.create_push_service_account && var.create_push_service_account_key ? google_secret_manager_secret.push_sa_key[0].name : null
}

output "docker_config_commands" {
  description = "Commands to configure Docker for this registry"
  value = var.format == "DOCKER" ? {
    configure_docker = "gcloud auth configure-docker ${var.location}-docker.pkg.dev"
    tag_image       = "docker tag <image> ${var.location}-docker.pkg.dev/${var.project_id}/${var.repository_id}/<image>"
    push_image      = "docker push ${var.location}-docker.pkg.dev/${var.project_id}/${var.repository_id}/<image>"
    pull_image      = "docker pull ${var.location}-docker.pkg.dev/${var.project_id}/${var.repository_id}/<image>"
  } : null
}

output "service_account_key_command" {
  description = "Command to retrieve the service account key from Secret Manager"
  value = var.create_push_service_account && var.create_push_service_account_key ? "gcloud secrets versions access latest --secret=${var.repository_id}-push-sa-key" : null
}