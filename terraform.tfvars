project_id              = "terraform-automation-by-ali12"
project_name            = "terraform-automation"
project_deletion_policy = "DELETE"
region                  = "us-central1"
ip_cidr_range           = "10.10.0.0/24"
ip_cidr_range_connector = "10.20.0.0/28"
enabled_apis = [
  "compute.googleapis.com",
  "sqladmin.googleapis.com",
  "secretmanager.googleapis.com",
  "run.googleapis.com",
  "vpcaccess.googleapis.com",
  "iam.googleapis.com",
  "servicenetworking.googleapis.com",
  "monitoring.googleapis.com",
  "logging.googleapis.com"
]
allowed_ports_sql = ["5432"]
target_tags_sql = ["sql"]
db_version     = "POSTGRES_15"
db_tier        = "db-f1-micro"
cloudrun_name  = "teamavail-service"
image_name     = "aliashmawy/teamavail-app"
container_port = 3000
container_name = "teamavail-app"
roles = [
  "roles/cloudsql.client",
  "roles/secretmanager.secretAccessor",
  "roles/vpcaccess.user"
]
alert_email = "aliashmawy595@gmail.com"
service_account_id = "cloudrun-sa"
display_name = "Cloud Run Service Account"