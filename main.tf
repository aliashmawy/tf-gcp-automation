terraform {
  backend "gcs" {
    bucket = "terraform-automation-remote-state"
  }
}
provider "google" {
  region = var.region
}

module "project" {
  source       = "./modules/project"
  project_name = "terraform-automation"
  project_id   = var.project_id
  enabled_apis = var.enabled_apis
}

module "network" {
  source       = "./modules/network"
  project_id   = var.project_id
  region       = var.region
  vpc_name     = "${var.project_name}-network"
  subnet1_name = "${var.project_name}-subnet"
}

module "firewall" {
  source        = "./modules/firewall"
  vpc_name      = module.network.vpc_name
  project_id = var.project_id
  firewall_name = "${var.project_name}-firewall"
  allowed_ports = [5432]
  #change this in the future to tags outputted from sql module
  target_tags = ["sql"]
}