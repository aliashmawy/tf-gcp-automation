resource "google_vpc_access_connector" "connector" {
  name         = var.connector_name
  project      = var.project_id
  region       = var.region
  network      = var.network_id
  ip_cidr_range = var.ip_cidr_range_connector
  min_instances = 1
  max_instances = 3
}