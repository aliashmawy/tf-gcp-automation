variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "ip_cidr_range" {
  description = "IP CIDR range for the subnet"
  type        = string
}

variable "region" {
  description = "Region for the subnet"
  type        = string
}
