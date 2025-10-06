resource "google_cloud_run_service" "default" {
  name     = var.cloudrun_name
  location = var.region
  project = var.project_id
  autogenerate_revision_name = true

  template {
    spec {
      service_account_name = var.sa_email
      containers {
        name = "${var.container_name}"
        image = "${var.image_name}"
        ports {
          container_port = var.container_port
        }
        env {
          name  = "DB_HOST"
          value = var.db_host
        }

        env {
          name  = "DB_PORT"
          value = var.db_port
        }

        env {
          name  = "DB_NAME"
          value = var.db_name
        }

        env {
          name  = "DB_USER"
          value = var.db_user_name
        }

        env {
          name = "DB_PASSWORD"
          value_from {
            secret_key_ref {
              name = var.db_password_secret
              key  = "latest"
            }
          }
        }
        }
      }
      metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = "${var.vpc_connector_id}"
        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
      }
    }
    }

    
  }

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.default.location
  project     = google_cloud_run_service.default.project
  service     = google_cloud_run_service.default.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
