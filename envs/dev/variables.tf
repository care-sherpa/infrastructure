#
# Development Environment Variables
#

variable "project_id" {
  description = "The GCP project ID for development"
  type        = string
  default     = "caresherpadev-448722"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}