#
# Security Infrastructure Module
#

# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "docker_registry" {
  location      = var.region
  project       = var.project_id
  repository_id = var.registry_config.repository_id
  description   = var.registry_config.description
  format        = "DOCKER"

  cleanup_policy_dry_run = var.registry_config.cleanup_policy_dry_run

  dynamic "cleanup_policies" {
    for_each = var.registry_config.cleanup_policies
    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.conditions
        content {
          tag_state             = condition.value.tag_state
          tag_prefixes          = condition.value.tag_prefixes
          version_name_prefixes = condition.value.version_name_prefixes
          package_name_prefixes = condition.value.package_name_prefixes
          older_than            = condition.value.older_than
        }
      }
    }
  }
}

# Static IP address for load balancer
resource "google_compute_global_address" "lb_ip" {
  name         = var.static_ip_config.name
  project      = var.project_id
  address_type = "EXTERNAL"
  description  = var.static_ip_config.description
}

# IAM Service Accounts for GKE nodes
resource "google_service_account" "gke_node_service_account" {
  for_each = var.service_accounts

  account_id   = "${var.name_prefix}${each.value.account_id}"
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.project_id
}

# IAM bindings for service accounts
resource "google_project_iam_member" "gke_node_service_account_roles" {
  for_each = local.service_account_roles

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.gke_node_service_account[each.value.service_account].email}"
}

# Locals for flattening service account roles
locals {
  service_account_roles = merge([
    for sa_key, sa_config in var.service_accounts : {
      for role in sa_config.roles : "${sa_key}-${replace(role, "/", "-")}" => {
        service_account = sa_key
        role           = role
      }
    }
  ]...)
}

# Generate random passwords for database users
resource "random_password" "db_user_passwords" {
  for_each = var.db_users
  
  length  = 16
  special = true
}

# Store database user passwords in Secret Manager
resource "google_secret_manager_secret" "db_user_passwords" {
  for_each = var.db_users
  
  project   = var.project_id
  secret_id = "${var.name_prefix}db-${each.key}-password"
  
  replication {
    auto {}
  }

  labels = {
    environment = "dev"
    type        = "database-password"
    user        = each.key
  }
}

resource "google_secret_manager_secret_version" "db_user_passwords" {
  for_each = var.db_users
  
  secret      = google_secret_manager_secret.db_user_passwords[each.key].name
  secret_data = random_password.db_user_passwords[each.key].result
}