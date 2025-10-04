variable "vpc_name" {
  description = "name of network"
  type = string
}

variable "project_id" {
  description = "project id"
  type = string
}

variable "project_name" {
  description = "project_name"
  type = string
}

variable "region" {
  description = "region"
  type = string
}

variable "db_version" {
  description = "postgres db version"
  type = string
}

variable "db_tier" {
  description = "sql instance tier"
  type = string
}

variable "db_password_secret" {
  description = "secret name"
  type = string
}

variable "network_self_link" {
  description = "network link"
  type = string
}

variable "network_id" {
  description = "id of network"
  type = string
}