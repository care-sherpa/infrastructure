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

variable "authorized_networks" {
  description = "List of authorized networks for database access"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "Joseph Home"
      value = "68.89.9.20/32"
    },
    {
      name  = "Ledom Home" 
      value = "23.114.226.239/32"
    }
  ]
}

variable "gke_authorized_networks" {
  description = "List of authorized networks for GKE cluster master access"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "10.10.0.0/16"
      display_name = "Dev VPC Subnet"
    },
    {
      cidr_block   = "68.89.9.20/32"
      display_name = "Joseph Home"
    },
    {
      cidr_block   = "23.114.226.239/32"
      display_name = "Ledom Home"
    }
  ]
}