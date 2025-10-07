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

variable "ip_cidr_range" {
  description = "cidr range for subnet1"
  type        = string
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
