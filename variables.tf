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

variable "db_version" {
  description = "version for postgres db"
  type        = string
}

variable "db_tier" {
  description = "db instance tier"
  type        = string
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


variable "labels" {
  type = map(string)
}
variable "billing_account" {
  type = string
}
