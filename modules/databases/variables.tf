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

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = ""
}

variable "network_self_link" {
  description = "Self link of the VPC network for private IP"
  type        = string
}

variable "private_vpc_connection" {
  description = "Private VPC connection dependency"
  type        = any
  default     = null
}

variable "postgres_authorized_networks" {
  description = "List of authorized networks for PostgreSQL database access"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "mysql_authorized_networks" {
  description = "List of authorized networks for MySQL database access"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "postgres_config" {
  description = "PostgreSQL database configuration"
  type = object({
    instance_name         = string
    database_version     = string
    tier                 = string
    disk_size           = number
    disk_type           = string
    availability_type   = string
    backup_enabled      = bool
    backup_start_time   = string
    deletion_protection = bool
    maintenance_day     = number
    maintenance_hour    = number
    secondary_zone      = string
    database_flags = list(object({
      name  = string
      value = string
    }))
  })
}

variable "mysql_config" {
  description = "MySQL database configuration"
  type = object({
    instance_name         = string
    database_version     = string
    tier                 = string
    disk_size           = number
    disk_type           = string
    availability_type   = string
    backup_enabled      = bool
    backup_start_time   = string
    deletion_protection = bool
    maintenance_day     = number
    maintenance_hour    = number
    secondary_zone      = string
    database_flags = list(object({
      name  = string
      value = string
    }))
  })
}

variable "postgres_databases" {
  description = "List of PostgreSQL databases to create"
  type        = list(string)
  default     = []
}

variable "db_users" {
  description = "Database users to create"
  type = map(object({
    description = string
    databases   = list(string)
  }))
  default = {}
}

variable "db_user_passwords" {
  description = "Passwords for database users (from security module)"
  type        = map(string)
  default     = {}
  sensitive   = true
}