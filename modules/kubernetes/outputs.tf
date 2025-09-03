#
# Kubernetes Module Outputs
#

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location (region or zone) of the cluster"
  value       = google_container_cluster.primary.location
}

output "node_pools" {
  description = "Node pool information"
  value = {
    apps = {
      name = google_container_node_pool.apps.name
      id   = google_container_node_pool.apps.id
    }
    data = {
      name = google_container_node_pool.data.name
      id   = google_container_node_pool.data.id
    }
  }
}

output "workload_identity_pool" {
  description = "The Workload Identity pool"
  value       = google_container_cluster.primary.workload_identity_config[0].workload_pool
}