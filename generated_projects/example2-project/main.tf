provider "google" {
  region = var.region
}

module "project" {
  source                  = "../../modules/project"
  project_name            = var.project_name
  project_id              = var.project_id
  enabled_apis            = var.enabled_apis
  project_deletion_policy = var.project_deletion_policy
}

module "network" {
  source        = "../../modules/network"
  project_id    = module.project.project_id
  region        = var.region
  vpc_name      = "${var.project_name}-network"
  subnet1_name  = "${var.project_name}-subnet"
  ip_cidr_range = var.ip_cidr_range
}

module "firewall" {
  source            = "../../modules/firewall"
  vpc_name          = module.network.vpc_name
  project_id        = module.project.project_id
  firewall_name     = "${var.project_name}-firewall"
  allowed_ports_sql = var.allowed_ports_sql
  target_tags_sql   = var.target_tags_sql
  protocol_type     = var.protocol_type
  source_ranges     = var.source_ranges
}
