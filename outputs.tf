output "load_balancer_ip" {
  description = "External IP address of the HTTP load balancer"
  value       = module.load-balancer.lb_ip_address
}

output "cloud_run_url" {
  description = "Public URL of the Cloud Run service"
  value       = module.cloudrun.cloud_run_service_url
}
