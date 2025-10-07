## tf-gcp-automation

This repository provisions a complete, Google Cloud Platform (GCP) environment using Terraform. It automates:

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
    - cloudrun/
    - sql/
    - firewall/
    - iam/
    - load-balancer/
    - monitoring/
    - network/
    - project/
    - secrets/
    - vpc_connector/
  - outputs.tf
  - README.md
  - configs/
    - example1.yaml
    - example2.yaml
  - generated_projects/
    - <project-name>/
      - main.tf
      - variables.tf
      - terraform.tfvars
      - plan.txt
  - scripts/
    - deploy.py
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

## Workflow (GitHub Actions)

What it does:
- Triggers on pushes to `main` that change files in `configs/*.yaml` or `configs/*.yml`
- Can also be run manually from the Actions tab (`workflow_dispatch`)
- Runs the  script to create projects and produce Terraform plans

Steps:
1. Checkout the repo
2. Optionally detect newly added files under `configs/`
3. Setup Python 3.10 and install `pyyaml`, `pydot`
4. Authenticate to Google Cloud using `${{ secrets.GCP_Credentials }}`
5. Install `gcloud` and set the `project_id` (replace `your-gcp-project-id` in the workflow)
6. Setup Terraform 1.8.4
7. Run `python scripts/deploy.py --overwrite`

Notes:
- Make sure to add the secret `GCP_Credentials` in your repo settings (format: service account JSON)

---

## YAML-driven project generator (scripts/deploy.py)

Use `scripts/deploy.py` to generate tailored Terraform projects from YAML files under `configs/`. For each YAML file, the script:
- Parses selected modules and their input variables
- Builds a module dependency map using `terraform graph`
- Validates dependencies, then generates a filtered `main.tf` and `variables.tf`
- Writes a `terraform.tfvars` with only the needed variables
- Runs `terraform init` and `terraform plan`, saving the output to `plan.txt`

### Prerequisites
- Python 3.8+
- Packages: `pyyaml`, `pydot`
- System dependency: Graphviz (required by `pydot`)

Install on Ubuntu/Debian:
```bash
sudo apt-get update && sudo apt-get install -y graphviz
python3 -m pip install --upgrade pip
python3 -m pip install pyyaml pydot
```

### YAML layout (high level)
Each file in `configs/` should define a project name and which modules are selected, along with their inputs. Example outline:
```yaml
project_name: example1-project
modules:
  project:
    selected: true
    project_id: my-gcp-project
    region: us-central1
  network:
    selected: true
    vpc_name: my-vpc
  sql:
    selected: false
```

Only modules with `selected: true` are included. Their provided keys become variables in the generated `terraform.tfvars`.

### How it works (internals)
- The script runs `terraform graph` against the repo root to build a dependency map and avoid generating invalid combinations
- It filters the template `main.tf` to include only the selected modules, automatically fixing `source` paths for generated projects
- It filters `variables.tf` to include only variables required by the selected modules, plus core variables like `project_id`, `region`, `project_name`
- It then runs `terraform init` and `terraform plan` inside each generated project directory

### Running the generator
Run from the repository root:
```bash
python3 scripts/deploy.py              # generate projects for all YAMLs in configs/
python3 scripts/deploy.py --overwrite  # allow overwriting existing generated project folders
```

Output appears under `generated_projects/<project_name>/`:
```text
generated_projects/
  example1-project/
    main.tf
    variables.tf
    terraform.tfvars
    plan.txt
```

Notes:
- The script exits non‑zero if any project fails validation or planning
- You can subsequently `cd generated_projects/<project_name>` and run `terraform apply` if the plan looks good

---

## What gets created (Modules)
- `modules/project`: Creates/uses a GCP project and enables required APIs
- `modules/network`: VPC, subnetwork, and outputs for self links/ids
- `modules/firewall`: Ingress rules (e.g., port 5432 to SQL with tag `sql`)
- `modules/sql`: PostgreSQL instance, database, users; peering/network wiring; uses Secret Manager for password
- `modules/secrets`: Creates secrets (e.g., DB password) and returns names/versions
- `modules/vpc_connector`: Serverless VPC Access connector for Cloud Run -> VPC
- `modules/iam`: Service account for Cloud Run and role bindings from `roles`
- `modules/cloudrun`: Cloud Run service; container image, port, envs, VPC connector, SA
- `modules/load-balancer`: External HTTPS Load Balancer fronting Cloud Run
- `modules/monitoring`: Alerting policy to `alert_email` for service health

The root `main.tf` composes these modules together with outputs passed between them.

---

## Problems and notes from development

### Problem 1: Missing dependencies in `terraform graph`
- Some modules didn’t appear to depend on core modules like `project` in the graph
- Root cause: Variables such as `project_id` were passed directly via `tfvars` to downstream modules instead of being wired from `module.project` outputs. Terraform then cannot infer the dependency
- Prefer wiring like:
```hcl
module "sql" {
  source     = "./sql"
  project_id = module.project.project_id
}
```

### Problem 2: Repeated inputs in YAML
- Duplicated values like `project_id` across multiple modules make YAML verbose and error‑prone
- Used already existing template and copied necessary files and filtered only the selected modules

### Problem 3: Duplicate/self dependencies in the graph
- The raw `terraform graph` may contain duplicate edges and self‑dependencies
- Deduplicate and drop self‑references when parsing:
```python
for mod, deps in dependencies.items():
    unique_deps = sorted(set(d for d in deps if d != mod))
    dependencies[mod] = unique_deps
```

---

## Future enhancements (ideas)

### Automate creating the remote backend bucket
You can auto-create a GCS bucket for state, then write a `backend.tf` file that points to it:
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
  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "${google_storage_bucket.default.name}"
    }
  }
  EOT
}
```

### Use Cloud SQL socket with Cloud Run
Instead of passing DB host/port/envs, use the socket path `/cloudsql/<project>:<region>:<instance>` by adding annotations in the Cloud Run service:
```hcl
metadata {
  annotations = {
    "autoscaling.knative.dev/maxScale"      = "1000"
    "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
    "run.googleapis.com/client-name"        = "terraform"
  }
}
```
