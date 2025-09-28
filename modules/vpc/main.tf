resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc.self_link
}
output "network_self_link" {
  description = "Self link of the created VPC"
  value       = google_compute_network.vpc.self_link
}

output "subnet_self_link" {
  description = "Self link of the created Subnet"
  value       = google_compute_subnetwork.subnet.self_link
}
