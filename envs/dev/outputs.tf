#
# Development Environment Outputs
#

output "network_info" {
  description = "Networking information"
  value = {
    network_name      = module.networking.network_name
    network_self_link = module.networking.network_self_link
    subnet_name       = module.networking.subnet_name
    subnet_self_link  = module.networking.subnet_self_link
  }
}

output "database_info" {
  description = "Database information"
  value = {
    postgres_instance_name = module.databases.postgres_instance_name
    postgres_connection_name = module.databases.postgres_instance_connection_name
    mysql_instance_name = module.databases.mysql_instance_name
    mysql_connection_name = module.databases.mysql_instance_connection_name
  }
  sensitive = true
}

output "kubernetes_info" {
  description = "Kubernetes cluster information"
  value = {
    cluster_name     = module.kubernetes.cluster_name
    cluster_location = module.kubernetes.cluster_location
    cluster_endpoint = module.kubernetes.cluster_endpoint
  }
  sensitive = true
}

output "security_info" {
  description = "Security resources information"
  value = {
    artifact_registry_name = module.security.artifact_registry.name
    static_ip_address      = module.security.static_ip_address.address
    service_accounts       = keys(module.security.service_accounts)
    db_user_secrets        = module.security.db_user_secrets
  }
}

output "db_user_info" {
  description = "Database user information for applications"
  value = {
    users = keys(local.db_users)
    secret_names = {
      for user, secret in module.security.db_user_secrets : user => secret.secret_name
    }
  }
}