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

module "sql" {
  source             = "../../modules/sql"
  project_id         = module.project.project_id
  project_name       = var.project_name
  region             = var.region
  vpc_name           = module.network.vpc_name
  db_version         = var.db_version
  db_tier            = var.db_tier
  db_password_secret = module.secrets.db_password_secret_name
  network_self_link  = module.network.network_self_link
  network_id         = module.network.network_id
  sql_user           = var.sql_user
}

module "secrets" {
  source       = "../../modules/secrets"
  project_id   = module.project.project_id
  project_name = var.project_name
  secret_id    = var.secret_id
}

module "cloudrun" {
  source             = "../../modules/cloudrun"
  project_id         = module.project.project_id
  cloudrun_name      = var.cloudrun_name
  region             = var.region
  db_name            = module.sql.db_name
  db_port            = module.sql.db_port
  image_name         = var.image_name
  container_name     = var.container_name
  db_host            = module.sql.db_host
  db_user_name       = module.sql.db_user_name
  db_password_secret = module.secrets.db_password_secret
  container_port     = var.container_port
  vpc_connector_id   = module.vpc_connector.vpc_connector_id
  sa_email           = module.iam.sa_email
}

module "vpc_connector" {
  source                  = "../../modules/vpc_connector"
  project_id              = module.project.project_id
  network_id              = module.network.network_id
  connector_name          = "${var.project_name}-con"
  region                  = var.region
  ip_cidr_range_connector = var.ip_cidr_range_connector
}

module "iam" {
  source             = "../../modules/iam"
  project_id         = module.project.project_id
  service_account_id = var.service_account_id
  display_name       = var.display_name
  roles              = var.roles
}

module "load-balancer" {
  source                 = "../../modules/load-balancer"
  project_name           = var.project_name
  project_id             = module.project.project_id
  region                 = var.region
  cloud_run_service_name = module.cloudrun.cloud_run_service_name
  
}

module "monitoring" {
  source                 = "../../modules/monitoring"
  project_id             = module.project.project_id
  project_name           = var.project_name
  cloud_run_service_name = module.cloudrun.cloud_run_service_name
  alert_email            = var.alert_email
}
