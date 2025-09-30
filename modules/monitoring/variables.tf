variable "project_id" {}
variable "project_name" {}
variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service to monitor"
  type        = string
}

variable "alert_email" {
  description = "my email to send alert to"
  type = string
}