output "postgres_instance_name" {
  value = google_sql_database_instance.main-db.name
}

output "postgres_instance_connection_name" {
  value = google_sql_database_instance.main-db.connection_name
}

output "postgres_instance_ip_settings" {
  value = google_sql_database_instance.main-db.ip_address
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