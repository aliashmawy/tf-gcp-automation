module "project" {
  source           = "./modules/project"
  project_id       = "dev-intern-poc"
  billing_account  = "0147B7-2560AC-CA1A2B"
  labels           = { owner = "intern", environment = "test" }
  apis             = ["compute.googleapis.com", "iam.googleapis.com"]
}
module "vpc" {
  source       = "./modules/vpc"
  vpc_name     = "dev-intern-vpc"
  subnet_name  = "dev-intern-subnet"
  ip_cidr_range= "10.0.0.0/24"
  region       = "us-central1"
}
module "firewall" {
  source        = "./modules/firewall"
  firewall_name = "allow-sql"
  network       = module.vpc.vpc_self_link
  allowed_ports = ["5432"]
  target_tags   = ["sql-server"]
}

output "sql_firewall_id" {
  value = module.firewall.firewall_id
}

output "sql_firewall_self_link" {
  value = module.firewall.firewall_self_link
}

provider "google" {
  project = "besho-project"
  region  = "us-central1"
}
