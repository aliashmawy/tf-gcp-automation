variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "logs_bucket_name" {
  description = "Name of the storage bucket for logs"
  type        = string
}

variable "alert_policy_name" {
  description = "Name of the monitoring alert policy"
  type        = string
}

variable "notification_email" {
  description = "Email address for receiving alerts"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU usage threshold to trigger alert"
  type        = number
  default     = 80
}
