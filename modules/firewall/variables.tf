variable "firewall_name" {
  type        = string
  description = "Name of the firewall rule"
}

variable "network" {
  type        = string
  description = "VPC network self_link"
}

variable "allowed_ports" {
  type        = list(string)
  description = "Allowed TCP ports"
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
