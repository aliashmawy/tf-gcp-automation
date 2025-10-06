project_id   = "beshoy-intern-proj-88"
project_name = "beshoy-intern-proj-88"
vpc_name     = "beshoy-intern-proj-88-network"
subnet1_name = "beshoy-intern-proj-88-subnet1"


billing_account = "0147B7-2560AC-CA1A2B"
region = "us-central1"
ip_cidr_range = "10.0.0.0/16"
ip_cidr_range_connector = "10.8.0.0/28"
enabled_apis = ["compute.googleapis.com", "iam.googleapis.com", "cloudsql.googleapis.com"]
labels = {
  owner = "intern"
  environment = "test"
}
cloudrun_name = "teamavail-service"
image_name = "gcr.io/my-project/my-image"
container_name = "app-container"
db_version = "POSTGRES_15"
db_tier = "db-f1-micro"
roles = ["roles/cloudsql.client", "roles/secretmanager.secretAccessor", "roles/vpcaccess.user"]
alert_email = "alerts@example.com"