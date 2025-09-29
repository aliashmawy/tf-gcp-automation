resource "google_compute_firewall" "sql_firewall" {
  name    = var.firewall_name
  network = var.network

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }

  target_tags   = var.target_tags
  source_ranges = var.source_ranges
}

output "firewall_id" {
  value       = google_compute_firewall.sql_firewall.id
  description = "The ID of the firewall rule"
}

output "firewall_self_link" {
  value       = google_compute_firewall.sql_firewall.self_link
  description = "The self_link of the firewall rule"
}

