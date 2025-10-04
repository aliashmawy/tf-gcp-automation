output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "network_self_link" {
  value = google_compute_network.vpc.self_link
}

output "network_id" {
  value = google_compute_network.vpc.id
}