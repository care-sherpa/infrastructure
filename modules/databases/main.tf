#
# Database Infrastructure Module
#

# PostgreSQL Database Instance
resource "google_sql_database_instance" "main_apps_db" {
  name                = "${var.name_prefix}${var.postgres_config.instance_name}"
  project             = var.project_id
  region              = var.region
  database_version    = var.postgres_config.database_version
  deletion_protection = var.postgres_config.deletion_protection

  depends_on = [var.private_vpc_connection]

  settings {
    tier              = var.postgres_config.tier
    availability_type = var.postgres_config.availability_type
    disk_size         = var.postgres_config.disk_size
    disk_type         = var.postgres_config.disk_type

    # Backup configuration
    backup_configuration {
      enabled                        = var.postgres_config.backup_enabled
      start_time                     = var.postgres_config.backup_start_time
      point_in_time_recovery_enabled = false
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
      transaction_log_retention_days = 7
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled    = true
      private_network = var.network_self_link
      
      dynamic "authorized_networks" {
        for_each = var.postgres_authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
      
      ssl_mode    = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    }

    # Location preferences
    location_preference {
      zone           = var.zone
      secondary_zone = var.postgres_config.secondary_zone
    }

    # Maintenance window
    maintenance_window {
      day  = var.postgres_config.maintenance_day
      hour = var.postgres_config.maintenance_hour
    }

    # Database flags
    dynamic "database_flags" {
      for_each = var.postgres_config.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
    }
  }
}

# MySQL Database Instance
resource "google_sql_database_instance" "prod_mysql_apps_db" {
  name                = "${var.name_prefix}${var.mysql_config.instance_name}"
  project             = var.project_id
  region              = var.region
  database_version    = var.mysql_config.database_version
  deletion_protection = var.mysql_config.deletion_protection

  depends_on = [var.private_vpc_connection]

  settings {
    tier              = var.mysql_config.tier
    availability_type = var.mysql_config.availability_type
    disk_size         = var.mysql_config.disk_size
    disk_type         = var.mysql_config.disk_type

    # Backup configuration
    backup_configuration {
      enabled                        = var.mysql_config.backup_enabled
      start_time                     = var.mysql_config.backup_start_time
      binary_log_enabled            = true
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
      transaction_log_retention_days = 7
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled    = true
      private_network = var.network_self_link
      
      dynamic "authorized_networks" {
        for_each = var.mysql_authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
      
      ssl_mode    = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    }

    # Location preferences
    location_preference {
      zone           = var.zone
      secondary_zone = var.mysql_config.secondary_zone
    }

    # Maintenance window
    maintenance_window {
      day  = var.mysql_config.maintenance_day
      hour = var.mysql_config.maintenance_hour
    }

    # Database flags
    dynamic "database_flags" {
      for_each = var.mysql_config.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Insights configuration
    insights_config {
      query_insights_enabled    = true
      query_plans_per_minute    = 5
      query_string_length       = 1024
      record_application_tags   = true
      record_client_address     = true
    }
  }
}

# PostgreSQL Databases
resource "google_sql_database" "postgres_databases" {
  for_each = toset(var.postgres_databases)
  
  name     = each.value
  instance = google_sql_database_instance.main_apps_db.name
  project  = var.project_id
  charset  = "UTF8"
  collation = "en_US.UTF8"
}

# PostgreSQL users
resource "google_sql_user" "postgres_users" {
  for_each = var.db_users
  
  name     = each.key
  instance = google_sql_database_instance.main_apps_db.name
  project  = var.project_id
  password = var.db_user_passwords[each.key]
  type     = "BUILT_IN"
}

# MySQL users  
resource "google_sql_user" "mysql_users" {
  for_each = var.db_users
  
  name     = each.key
  instance = google_sql_database_instance.prod_mysql_apps_db.name
  project  = var.project_id
  password = var.db_user_passwords[each.key]
  host     = "%"  # Allow connections from any host
}