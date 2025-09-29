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