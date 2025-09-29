resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
}

resource "google_logging_project_sink" "bucket_sink" {
  name                  = "logs-to-bucket"
  project               = var.project_id
  destination = "storage.googleapis.com/${google_storage_bucket.logs_bucket.name}"
  unique_writer_identity = true
}
output "sink_writer_identity" {
  description = "The identity used by the sink to write logs"
  value       = google_logging_project_sink.bucket_sink.writer_identity
}
resource "google_storage_bucket" "logs_bucket" {
  name     = "intern-logs-bucket"
  location = "US"
}

