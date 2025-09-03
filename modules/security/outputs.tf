#
# Security Module Outputs
#

output "artifact_registry" {
  description = "Artifact Registry repository information"
  value = {
    id   = google_artifact_registry_repository.docker_registry.id
    name = google_artifact_registry_repository.docker_registry.name
    location = google_artifact_registry_repository.docker_registry.location
  }
}

output "static_ip_address" {
  description = "The reserved static IP address for load balancer"
  value = {
    name    = google_compute_global_address.lb_ip.name
    address = google_compute_global_address.lb_ip.address
    id      = google_compute_global_address.lb_ip.id
  }
}

output "service_accounts" {
  description = "Created service accounts"
  value = {
    for key, sa in google_service_account.gke_node_service_account : key => {
      name         = sa.name
      email        = sa.email
      account_id   = sa.account_id
      display_name = sa.display_name
    }
  }
}

output "db_user_secrets" {
  description = "Secret Manager secret names for database user passwords"
  value = {
    for key, secret in google_secret_manager_secret.db_user_passwords : key => {
      secret_id   = secret.secret_id
      secret_name = secret.name
    }
  }
}

output "db_user_passwords" {
  description = "Generated database user passwords (sensitive)"
  value = {
    for key, password in random_password.db_user_passwords : key => password.result
  }
  sensitive = true
}