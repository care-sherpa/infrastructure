output "postgres_instance_name" {
  description = "Name of the PostgreSQL instance"
  value       = google_sql_database_instance.main_apps_db.name
}

output "postgres_instance_connection_name" {
  description = "Connection name of the PostgreSQL instance"
  value       = google_sql_database_instance.main_apps_db.connection_name
}

output "postgres_private_ip" {
  description = "Private IP address of the PostgreSQL instance"
  value       = google_sql_database_instance.main_apps_db.private_ip_address
}

output "postgres_public_ip" {
  description = "Public IP address of the PostgreSQL instance"
  value       = google_sql_database_instance.main_apps_db.public_ip_address
}

output "mysql_instance_name" {
  description = "Name of the MySQL instance"
  value       = google_sql_database_instance.prod_mysql_apps_db.name
}

output "mysql_instance_connection_name" {
  description = "Connection name of the MySQL instance"
  value       = google_sql_database_instance.prod_mysql_apps_db.connection_name
}

output "mysql_private_ip" {
  description = "Private IP address of the MySQL instance"
  value       = google_sql_database_instance.prod_mysql_apps_db.private_ip_address
}

output "mysql_public_ip" {
  description = "Public IP address of the MySQL instance"
  value       = google_sql_database_instance.prod_mysql_apps_db.public_ip_address
}