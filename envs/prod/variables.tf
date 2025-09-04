variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "caresherpaprod"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "postgres_authorized_networks" {
  description = "List of authorized networks for PostgreSQL database"
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
      name  = "Keragon3"
      value = "54.225.183.38"
    },
    {
      name  = "Keragon2"
      value = "34.197.3.75"
    },
    {
      name  = "Keragon1"
      value = "18.214.155.250"
    },
    {
      name  = "Ledom Home"
      value = "23.114.226.239/32"
    }
  ]
}

variable "mysql_authorized_networks" {
  description = "List of authorized networks for MySQL database"
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
  description = "List of authorized networks for GKE cluster"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "10.1.0.0/16"
      display_name = "VPC Subnet"
    },
    {
      cidr_block   = "71.135.82.66/32"
      display_name = "Authorized Network 1"
    },
    {
      cidr_block   = "70.225.9.239/32"
      display_name = "Authorized Network 2"
    },
    {
      cidr_block   = "75.138.17.130/32"
      display_name = "Authorized Network 3"
    },
    {
      cidr_block   = "136.29.138.11/32"
      display_name = "Authorized Network 4"
    },
    {
      cidr_block   = "24.183.235.71/32"
      display_name = "Authorized Network 5"
    }
  ]
}