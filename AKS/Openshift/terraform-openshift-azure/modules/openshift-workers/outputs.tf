# modules/openshift-workers/outputs.tf

output "worker_profile_name" {
  description = "Name of the worker profile"
  value       = var.worker_profile_name
}

output "status" {
  description = "Status of the worker profile creation"
  value       = "Worker profile ${var.worker_profile_name} configured"
}
