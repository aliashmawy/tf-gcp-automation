# Enable Monitoring & Logging APIs
resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
}

# Create logs bucket
resource "google_storage_bucket" "logs_bucket" {
  name     = var.logs_bucket_name
  location = "US"
}

# Logging sink to bucket
resource "google_logging_project_sink" "bucket_sink" {
  name                    = "logs-to-bucket"
  project                 = var.project_id
  destination             = "storage.googleapis.com/${google_storage_bucket.logs_bucket.name}"
  unique_writer_identity  = true
}

# Notification channel (Email)
resource "google_monitoring_notification_channel" "email_channel" {
  project = var.project_id
  type    = "email"
  display_name = "Alert Email Channel"
  labels = {
    email_address = var.notification_email
  }
}

# CPU Alert Policy
resource "google_monitoring_alert_policy" "cpu_alert" {
  project = var.project_id
  display_name = var.alert_policy_name
  combiner     = "OR"

  conditions {
    display_name = "CPU Usage Condition"
    condition_threshold {
      filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
      duration = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = var.cpu_threshold
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_channel.id]
  enabled = true
}
output "logs_bucket_name" {
  description = "Name of the logs bucket"
  value       = google_storage_bucket.logs_bucket.name
}

output "sink_writer_identity" {
  description = "Writer identity for the logging sink"
  value       = google_logging_project_sink.bucket_sink.writer_identity
}

output "alert_policy_id" {
  description = "ID of the CPU alert policy"
  value       = google_monitoring_alert_policy.cpu_alert.id
}

output "notification_channel_id" {
  description = "ID of the notification email channel"
  value       = google_monitoring_notification_channel.email_channel.id
}

