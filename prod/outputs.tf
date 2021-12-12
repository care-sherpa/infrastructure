output "postgres_instance_name" {
  value = google_sql_database_instance.main-apps-db.name
}

output "postgres_instance_connection_name" {
  value = google_sql_database_instance.main-apps-db.connection_name
}

output "postgres_instance_ip_settings" {
  value = google_sql_database_instance.main-apps-db.ip_address
}

output "kubernetes_endpoint" {
  sensitive = true
  value     = module.gke.endpoint
}

output "client_token" {
  sensitive = true
  value     = base64encode(data.google_client_config.default.access_token)
}

output "ca_certificate" {
  value     = module.gke.ca_certificate
  sensitive = true
}

output "service_account" {
  description = "The default service account used for running nodes."
  value       = module.gke.service_account
}

output "docker_registry_id" {
  description = "Docker registry id"
  value       = google_artifact_registry_repository.cs-docker.id
}

output "docker_registry_name" {
  description = "Docker registry name"
  value       = google_artifact_registry_repository.cs-docker.name
}

output "load_balancer_static_ip" {
  description = "Static IP for the load balancer service"
  value       = google_compute_address.lb-address.address
}
