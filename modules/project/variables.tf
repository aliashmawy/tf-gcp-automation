variable "project_name" {
  description = "name of the project"
  type = string
}

variable "project_id" {
  description = "id of the project"
  type = string
}

variable "enabled_apis" {
  description = "List of APIs to enable in the project"
  type        = list(string)
}

variable "project_deletion_policy" {
  description = "deletion policy for project"
  type = string
}