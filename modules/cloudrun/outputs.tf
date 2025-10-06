output "cloud_run_service_name" {
  value = google_cloud_run_service.default.name
}

output "cloud_run_service_url" {
  description = "Public URL of the Cloud Run service"
  value       = google_cloud_run_service.default.status[0].url
}