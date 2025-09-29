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