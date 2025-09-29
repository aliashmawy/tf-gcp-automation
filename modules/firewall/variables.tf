variable "firewall_name" {
  description = "name of the firewall to allow sql connection"
  type = string
}

variable "vpc_name" {
  description = "name of vpc"
  type = string
}

variable "allowed_ports" {
  description = "ports to allow"
  type = list(string)
}

variable "target_tags" {
  type        = list(string)
  description = "VM target tags for the firewall"
}

variable "source_ranges" {
  type        = list(string)
  description = "Source IP ranges allowed"
  default     = ["0.0.0.0/0"] 
}

variable "project_id" {
  description = "project name"
  type = string
}