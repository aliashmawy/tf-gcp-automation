variable "cloudrun_name" {
  description = "name for cloud run service"
  type = string
}

variable "region" {
  description = "region for service"
  type = string
}

variable "project_id" {
  description = "project id"
  type = string
}

variable "container_name" {
  description = "name of container"
  type = string
}

variable "image_name" {
  description = "name of image used"
  type = string
}

variable "container_port" {
  description = "port for container"
  type = number
}
variable "db_host" {}
variable "db_name" {}
variable "db_port" {}
variable "db_user_name" {}
variable "db_password_secret" {}
variable "vpc_connector_id" {}
variable "sa_email" {}