output "db_password_secret_version" {
  value = google_secret_manager_secret_version.db_password.name
}

output "db_password_secret" {
  value = google_secret_manager_secret.db_password.secret_id
}

output "db_password_secret_name" {
  value = google_secret_manager_secret.db_password.name
}