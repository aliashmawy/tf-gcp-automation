variable "service_account_id" {
  description = "The ID of the service account"
  type        = string
}

variable "display_name" {
  description = "The display name of the service account"
  type        = string
}

variable "roles" {
  description = "List of IAM roles to attach to the service account"
  type        = list(string)
}

variable "project_id" {
  description = "The project ID where the service account will be created"
  type        = string
}