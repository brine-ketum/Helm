# modules/service-principal/variables.tf

variable "display_name" {
  description = "Display name for the application"
  type        = string
}

variable "description" {
  description = "Description of the service principal"
  type        = string
  default     = ""
}

variable "password_display_name" {
  description = "Display name for the password"
  type        = string
  default     = "Terraform Generated"
}

variable "password_end_date" {
  description = "End date for the password"
  type        = string
  default     = "2099-12-31T23:59:59Z"
}

variable "app_role_assignments" {
  description = "App role assignments"
  type = map(object({
    app_role_id        = string
    resource_object_id = string
  }))
  default = {}
}
