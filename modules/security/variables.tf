#
# Security Module Variables
#

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = ""
}

variable "registry_config" {
  description = "Artifact Registry configuration"
  type = object({
    repository_id           = string
    description            = string
    cleanup_policy_dry_run = bool
    cleanup_policies = list(object({
      id     = string
      action = string
      conditions = list(object({
        tag_state             = optional(string)
        tag_prefixes          = optional(list(string))
        version_name_prefixes = optional(list(string))
        package_name_prefixes = optional(list(string))
        older_than            = optional(string)
      }))
    }))
  })
  default = {
    repository_id           = "cs-docker"
    description            = "docker image repository"
    cleanup_policy_dry_run = true
    cleanup_policies       = []
  }
}

variable "static_ip_config" {
  description = "Static IP address configuration"
  type = object({
    name        = string
    description = string
  })
  default = {
    name        = "lb-svc-address"
    description = "Static IP for load balancer service"
  }
}

variable "service_accounts" {
  description = "Service accounts configuration"
  type = map(object({
    account_id   = string
    display_name = string
    description  = string
    roles        = list(string)
  }))
  default = {}
}

variable "db_users" {
  description = "Database users to create with passwords stored in Secret Manager"
  type = map(object({
    description = string
    databases   = list(string)  # Which databases this user should have access to
  }))
  default = {}
}