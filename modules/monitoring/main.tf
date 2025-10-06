resource "google_monitoring_alert_policy" "cloud_run_cpu" {
  display_name = "${var.cloud_run_service_name}-high-cpu"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Cloud Run CPU utilization above 80%"
    
    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.cloud_run_service_name}\" AND metric.type = \"run.googleapis.com/container/cpu/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.service_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.project_name}-email-notifications"
  project      = var.project_id
  type         = "email"
  
  labels = {
    email_address = var.alert_email
  }
}