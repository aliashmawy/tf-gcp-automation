## tf-gcp-automation

This repository provisions a complete, production-ready Google Cloud Platform (GCP) environment using Terraform. It automates:

- Project creation and API enablement
- VPC, subnetwork, and firewall rules
- Cloud SQL for PostgreSQL (with Secret Manager for credentials)
- Cloud Run service deployment (container image, port, service account, VPC connector)
- External HTTPS Load Balancer pointing to Cloud Run
- Monitoring alerting policy (email notifications)

### Project structure
```text
tf-gcp-automation/
  - main.tf
  - modules/
    - cloud-run/
    - cloud-sql/
    - firewall/
    - iam/
    - load-balancing/
    - monitoring/
    - network/
    - project/
    - secrets/
    - vpc-connector/
  - outputs.tf
  - README.md
  - terraform.tfvars
  - variables.tf
```

### How the structure works
The root `main.tf` wires together modular Terraform components under `modules/`. You configure a handful of input variables (see `variables.tf` or your `terraform.tfvars`), and apply once to create the full stack. Remote state is stored in a GCS bucket.

---

## Prerequisites
- Google Cloud account with billing enabled
- Permissions to create projects/resources in your organization/folder (or use an existing project id)
- Terraform >= 1.5
- gcloud CLI installed and authenticated

Authenticate locally so Terraform can use your credentials:
```bash
# Login to Google Cloud
gcloud auth login
# Provide Application Default Credentials for Terraform
gcloud auth application-default login
# Set default project if desired
gcloud config set project <YOUR_PROJECT_ID>
```

---

## Backend: Remote State
This repo is configured to use a GCS bucket for Terraform remote state:

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-automation-remote-state"
  }
}
```

Before running `terraform init`:
- Create the bucket named `terraform-automation-remote-state` in your GCP account
---

## Usage
Run from the repository root:

```bash
# Initialize providers, modules, and backend
terraform init

# See what will be created/changed
terraform plan

# Apply the infrastructure
terraform apply -auto-approve

# Tear everything down
terraform destroy -auto-approve
```

If you change backend settings or the bucket, re-run `terraform init -reconfigure`.

---

## What gets created (Modules)
- `modules/project`: Creates/uses a GCP project and enables required APIs
- `modules/network`: VPC, subnetwork, and outputs for self links/ids
- `modules/firewall`: Ingress rules (e.g., port 5432 to SQL with tag `sql`)
- `modules/cloud-sql`: PostgreSQL instance, database, users; peering/network wiring; uses Secret Manager for password
- `modules/secrets`: Creates secrets (e.g., DB password) and returns names/versions
- `modules/vpc-connector`: Serverless VPC Access connector for Cloud Run -> VPC
- `modules/iam`: Service account for Cloud Run and role bindings from `roles`
- `modules/cloud-run`: Cloud Run service; container image, port, envs, VPC connector, SA
- `modules/load-balancing`: External HTTPS Load Balancer fronting Cloud Run
- `modules/monitoring`: Alerting policy to `alert_email` for service health

The root `main.tf` composes these modules together with outputs passed between them.

---

## Future enhancements

### Automate remote backend like this

```hcl
resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name     = "${random_id.default.hex}-terraform-remote-backend"
  location = "US"

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "local_file" "default" {
  file_permission = "0644"
  filename        = "${path.module}/backend.tf"

  # You can store the template in a file and use the templatefile function for
  # more modularity, if you prefer, instead of storing the template inline as
  # we do here.
  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "${google_storage_bucket.default.name}"
    }
  }
  EOT
}
```

---

### Use Socket connection between SQL and Cloud run instead of defining all SQL envs in code

- This requires you edit in code to not expect all these envs
- Just expect a socket path for the DB like this `/cloudsql/project:region:instance`
- You make this work by adding annotations in Cloud Run Terraform code like this

```hcl
metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "1000"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
```
