resource "google_compute_firewall" "sql_firewall" {
  name    = var.firewall_name
  network = var.vpc_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports_sql
  }

  target_tags   = var.target_tags_sql
  source_ranges = var.source_ranges
}