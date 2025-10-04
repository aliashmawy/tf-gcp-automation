resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet1" {
  name          = var.subnet1_name
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}