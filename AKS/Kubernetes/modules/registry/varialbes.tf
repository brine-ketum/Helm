# modules/registry/variables.tf

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "location" {
  description = "Location for the registry"
  type        = string
  default     = "us-west2"
}

variable "repository_id" {
  description = "Repository ID"
  type        = string
}

variable "description" {
  description = "Description of the repository"
  type        = string
  default     = ""
}

variable "format" {
  description = "Repository format"
  type        = string
  default     = "DOCKER"
  
  validation {
    condition     = contains(["DOCKER", "MAVEN", "NPM", "PYTHON", "APT", "YUM"], var.format)
    error_message = "Format must be one of: DOCKER, MAVEN, NPM, PYTHON, APT, YUM."
  }
}

variable "labels" {
  description = "Labels to apply to the repository"
  type        = map(string)
  default     = {}
}

variable "immutable_tags" {
  description = "Whether tags are immutable"
  type        = bool
  default     = false
}

variable "allow_snapshot_overwrites" {
  description = "Allow snapshot overwrites (Maven only)"
  type        = bool
  default     = false
}

variable "maven_version_policy" {
  description = "Maven version policy"
  type        = string
  default     = "VERSION_POLICY_UNSPECIFIED"
}

variable "cleanup_policies" {
  description = "Cleanup policies for the repository"
  type = list(object({
    id     = string
    action = string
    condition = object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      version_name_prefixes = optional(list(string))
      package_name_prefixes = optional(list(string))
      older_than           = optional(string)
    })
    most_recent_versions = optional(object({
      package_name_prefixes = optional(list(string))
      keep_count           = optional(number)
    }))
  }))
  default = []
}

variable "reader_members" {
  description = "Members with reader access"
  type        = list(string)
  default     = []
}

variable "writer_members" {
  description = "Members with writer access"
  type        = list(string)
  default     = []
}

variable "admin_members" {
  description = "Members with admin access"
  type        = list(string)
  default     = []
}

variable "create_push_service_account" {
  description = "Create service account for pushing"
  type        = bool
  default     = true
}

variable "create_push_service_account_key" {
  description = "Create service account key for pushing"
  type        = bool
  default     = false
}

variable "enable_vulnerability_scanning" {
  description = "Enable vulnerability scanning"
  type        = bool
  default     = true
}