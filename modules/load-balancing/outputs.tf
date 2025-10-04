output "lb_ip_address" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "lb_url" {
  description = "Load balancer frontend URL"
  value       = "http://${google_compute_global_address.lb_ip.address}"
}
