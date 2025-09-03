variable "environment" {
  description = "Environment name (prod, dev)"
  type        = string
  validation {
    condition = contains(["prod", "dev"], var.environment)
    error_message = "Environment must be either 'prod' or 'dev'."
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = ""
}

variable "network_config" {
  description = "Network configuration"
  type = object({
    network_name        = string
    subnet_name         = string
    subnet_cidr         = string
    pods_cidr          = string
    services_cidr      = string
    pods_range_name    = string
    services_range_name = string
  })
}

variable "enable_gke" {
  description = "Enable GKE secondary IP ranges"
  type        = bool
  default     = true
}