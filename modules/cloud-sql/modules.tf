output "db_host" {
  value       = google_sql_database_instance.db.private_ip_address
  description = "The private IP address of the Cloud SQL instance"
}

output "db_name" {
  value       = google_sql_database_instance.db.name
  description = "The database name"
}

output "db_port" {
  value       = 5432
  description = "Database port"
}

output "db_user_name" {
  value       = google_sql_user.db_user.name
  description = "The SQL username"
}

output "db_password" {
  value       = data.google_secret_manager_secret_version.db_password.secret_data
  sensitive   = true
  description = "The SQL password (from Secret Manager)"
}
