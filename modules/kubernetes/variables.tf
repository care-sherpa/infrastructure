#
# Kubernetes Module Variables
#

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "zone" {
  description = "The GCP zone for the cluster"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = ""
}

variable "network_name" {
  description = "The VPC network name"
  type        = string
}

variable "subnet_name" {
  description = "The subnet name for the cluster"
  type        = string
}

variable "cluster_config" {
  description = "GKE cluster configuration"
  type = object({
    cluster_name                               = string
    pods_range_name                           = string
    services_range_name                       = string
    enable_private_nodes                      = bool
    enable_private_endpoint                   = bool
    master_ipv4_cidr_block                   = string
    disable_horizontal_pod_autoscaling       = bool
    disable_http_load_balancing              = bool
    disable_network_policy                   = bool
    enable_gce_persistent_disk_csi_driver    = bool
    enable_gke_backup_agent                  = bool
    autoscaling_profile                      = string
  })
}

variable "authorized_networks" {
  description = "List of authorized networks for master access"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "node_pools" {
  description = "Node pool configurations"
  type = object({
    apps = object({
      name              = string
      min_node_count    = number
      max_node_count    = number
      preemptible       = bool
      machine_type      = string
      disk_size_gb      = number
      disk_type         = string
      service_account   = string
      oauth_scopes      = list(string)
      auto_repair       = bool
      auto_upgrade      = bool
    })
    data = object({
      name              = string
      min_node_count    = number
      max_node_count    = number
      preemptible       = bool
      machine_type      = string
      disk_size_gb      = number
      disk_type         = string
      service_account   = string
      oauth_scopes      = list(string)
      auto_repair       = bool
      auto_upgrade      = bool
      taints = list(object({
        key    = string
        value  = string
        effect = string
      }))
    })
  })
}