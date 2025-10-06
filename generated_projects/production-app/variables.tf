variable "project_id" {
  description = "The ID of the project to create"
  type        = string
}

variable "region" {
  description = "region for the project"
  type        = string
}

variable "enabled_apis" {
  description = "List of APIs to enable in the project"
  type        = list(string)
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "project_deletion_policy" {
  description = "deletion policy for project"
  type = string
}

variable "secret_id" {
  description = "name of secret"
  type = string
}

variable "db_version" {
  description = "version for postgres db"
  type        = string
}

variable "db_tier" {
  description = "db instance tier"
  type        = string
}

variable "sql_user" {
  description = "user name for sql"
  type = string
}

variable "cloudrun_name" {
  description = "name for cloud run service"
  type        = string
}

variable "image_name" {
  description = "name of container's image"
  type        = string

}

variable "container_name" {
  description = "name of container"
  type        = string
}

variable "container_port" {
  description = "port for container"
  type        = number
}

variable "ip_cidr_range" {
  description = "cidr range for subnet1"
  type        = string
}

variable "ip_cidr_range_connector" {
  description = "cidr range for vpc connector instances"
  type        = string
}

variable "roles" {
  description = "roles for sa"
  type        = list(string)
}

variable "alert_email" {
  description = "alert email"
  type        = string
}

variable "service_account_id" {
  description = "serice account id for iam"
  type = string
}

variable "display_name" {
  description = "display name for service account"
  type = string
}

variable "allowed_ports_sql" {
  description = "allowed ports for sql instance"
  type = list(string)
}

variable "target_tags_sql" {
  description = "Targeted tags for sql firewall"
  type = list(string)
}

variable "protocol_type" {
  description = "protoctol type for allowed port"
  type = string
}

variable "source_ranges" {
  description = "Source IP ranges allowed"
  type        = list(string)
}
