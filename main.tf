module "project" {
  source           = "./modules/project"
  project_id       = "beshoy-intern-proj-01"
  billing_account  = "0147B7-2560AC-CA1A2B"
  labels           = { owner = "intern", environment = "test" }
  apis = ["compute.googleapis.com","iam.googleapis.com","run.googleapis.com","sqladmin.googleapis.com"]
}
module "vpc" {
  source       = "./modules/vpc"
  depends_on   = [module.project] 
  vpc_name     = "dev-intern-vpc"
  subnet_name  = "dev-intern-subnet"
  ip_cidr_range= "10.0.0.0/24"
  region       = "us-central1"
}
module "firewall" {
  source        = "./modules/firewall"
  depends_on = [module.vpc]
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
module "iam" {
  source             = "./modules/iam"
  project_id         = module.project.project_id
  service_account_id = "intern-sa"
  display_name       = "Intern Service Account"
  roles = [
    "roles/viewer",
    "roles/storage.admin"
  ]
}
module "cloudrun_sa" {
  source             = "./modules/iam"
  project_id         = module.project.project_id
  service_account_id = "cloudrun-sa"
  display_name       = "Cloud Run Service Account"
  roles = [
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/vpcaccess.user"
  ]
}
module "monitoring" {
  source      = "./modules/monitoring"
  project_id  = module.project.project_id
  logs_bucket = "intern-logs-bucket"
}


provider "google" {
  project = "dev-intern-poc"
  region  = "us-central1"
}

