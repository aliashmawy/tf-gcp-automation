#Reserve Internal IP range
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.project_name}-private-ip-range"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_name
}
#Establish connection between the cloud service and your network using the reserved IPs
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_sql_database_instance" "db" {
  name             = "${var.project_name}-db"
  project          = var.project_id
  region           = var.region
  database_version = var.db_version

  deletion_protection = false

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled = false
      private_network = var.network_self_link
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_user" "db_user" {
  name     = "teamavail"
  instance = google_sql_database_instance.db.name
  password = data.google_secret_manager_secret_version.db_password.secret_data
  project  = var.project_id
}

data "google_secret_manager_secret_version" "db_password" {
  secret = var.db_password_secret
}