project_id              = "terraform-automation-by-ali12"
project_name            = "terraform-automation"
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
