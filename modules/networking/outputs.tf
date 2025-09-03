output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.private_network.name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.private_network.self_link
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "Self link of the subnet"
  value       = google_compute_subnetwork.subnet.self_link
}

output "pods_range_name" {
  description = "Name of the pods IP range"
  value       = var.enable_gke ? var.network_config.pods_range_name : null
}

output "services_range_name" {
  description = "Name of the services IP range"
  value       = var.enable_gke ? var.network_config.services_range_name : null
}

output "private_vpc_connection" {
  description = "Private VPC connection for databases"
  value       = google_service_networking_connection.private_vpc_connection
}