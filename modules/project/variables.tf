variable "project_id" { type = string }
variable "project_name" { type = string }

variable "billing_account" { type = string }
variable "labels" { type = map(string) }
variable "enabled_apis" { type = list(string) }
variable "region" { type = string }
variable "ip_cidr_range" { type = string }
