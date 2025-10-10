## Terraform-GCP-Automation

This repository provisions a complete, Google Cloud Platform (GCP) environment using Terraform. 

## Project structure

```
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
    - __init__.py
    - deploy.py
    - terraform_utils.py
    - config_loader.py
    - template_processor.py
    - project_generator.py
  - terraform.tfvars
  - variables.tf

```

---

## What it does?

1. The `modules/` directory is used as a template for newly generated projects but with different variables
2. Each new YAML file in `configs/` represents a project to be created with specific requirements
3. The python script then generates new terraform projects in `generated_projects/` for each YAML file in the `configs/` by passing the variables from the YAML file to the existing modules in the repository
4. The GitHub Actions workflow is used to trigger the script when a new YAML files are added to `configs/` (Only when new files are added)

---

## Why The Script?

- The Script uses existing modules that are production-ready, the user only has to insert his own input variables in a YAML file and the script will do the rest.
- You can also specify some of the modules and not required to use all of them to make the project work, as the script can handle dependency issues between modules.

---

### How the Terraform template structure works

- The root `main.tf` wires together modular Terraform components under `modules/`.
- The existing template is used to help extract a dependency map using `terraform graph` for the existing modules.
    - This is important because new projects specified in the YAML file can have dependency issues between differrent modules

---

## Terraform Prerequisites

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

### Python Prerequisites

- Python 3.8+
- Packages: `pyyaml`, `pydot`
- System dependency: Graphviz (required by `pydot`)

Install on Ubuntu/Debian:

```bash
sudo apt-get update && sudo apt-get install -y graphviz
python3 -m pip install --upgrade pip
python3 -m pip install pyyaml pydot

```

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

## Terraform Modules

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

## Workflow (GitHub Actions)

### What it does:

- Triggers on pushes to `main` that change files in `configs/*.yaml` or `configs/*.yml`
- Can also be run manually from the Actions tab (`workflow_dispatch`)
- Runs the script to create projects and produce Terraform plans

### Prerequisites:

- GCP credentials (service account JSON), git username and email in repository secrets
- You must also generate a Slack webhook for your channel and add it as a repository secret.

### Steps:

1. Checkout the repo
2. Optionally detect newly added files under `configs/`
3. Setup Python 3.10 and install `pyyaml`, `pydot`
4. Authenticate to Google Cloud using `${{ secrets.GCP_Credentials }}`
5. Install `gcloud` and set the `project_id` (replace `your-gcp-project-id` in the workflow)
6. Setup Terraform 1.8.4
7. Run `python scripts/deploy.py --overwrite`
8. Push new changes with the new project generated to a new branch in the same repository
9. Send a notification to your slack channel if workflow succeeded

---

## Python Script (scripts/)

The script is organized into focused modules for better maintainability. The main entry point is `scripts/deploy.py` which orchestrates the entire process.

### Script modules overview

### **`deploy.py`** - Main orchestration script

- Entry point for the entire generation process
- Loads configurations and coordinates all other modules
- Handles command-line arguments and provides summary output

### **`terraform_utils.py`** - Terraform graph and dependency management

- `get_terraform_graph()` - Runs `terraform graph` command
- `parse_terraform_graph()` - Parses graph output to extract module dependencies
- `load_dependency_map()` - Builds complete dependency map from template
- `validate_dependencies()` - Ensures selected modules have all required dependencies

### **`config_loader.py`** - YAML configuration handling

- `load_yaml_configs()` - Loads all YAML files from `configs/` directory
- `extract_selected_modules()` - Extracts modules marked as `selected: true`

### **`template_processor.py`** - Template filtering and generation

- `filter_main_tf()` - Filters `main.tf` to include only selected modules
- `filter_variables_tf()` - Filters `variables.tf` to include only needed variables
- `generate_tfvars()` - Creates `terraform.tfvars` from module configurations
- `format_tfvars_value()` - Formats values for Terraform variable files

### **`project_generator.py`** - Project creation and Terraform operations

- `generate_project_structure()` - Creates project directories
- `copy_and_filter_templates()` - Copies and filters template files
- `run_terraform_init()` - Runs `terraform init` in project directories
- `run_terraform_plan()` - Runs `terraform plan` and saves output to `plan.txt`

### **`__init__.py`** - Makes `scripts/` a Python package for proper imports

---

## How it works

For each YAML file, the system:

1. Parses selected modules and their input variables
2. Builds a module dependency map using `terraform graph`
3. Validates dependencies, then generates filtered `main.tf` and `variables.tf`
4. Writes a `terraform.tfvars` with only the needed variables
5. Runs `terraform init` and `terraform plan`, saving output to `plan.txt`

---

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

---

### Running the script

Run from the repository root:

```bash
python3 scripts/deploy.py              # generate projects for all YAMLs in configs/
python3 scripts/deploy.py --overwrite  # allow overwriting existing generated project folders
python3 scripts/deploy.py --help       # show available options

```

Output appears under `generated_projects/<project_name>/`:

```
generated_projects/
  example1-project/
    main.tf
    variables.tf
    terraform.tfvars
    plan.txt

```

### Notes:

- The script exits non‑zero if any project fails validation or planning
- You can subsequently `cd generated_projects/<project_name>` and run `terraform apply` if the plan looks good

---

## Problems Faced

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
- Used already existing template and copied necessary files and filtered only the selected modules, as shown in `filter_main_tf()`

### Problem 3: Duplicate/self dependencies in the graph

- The raw `terraform graph` may contain duplicate edges and self‑dependencies
- Deduplicate and drop self‑references when parsing:

```python
for mod, deps in dependencies.items():
    unique_deps = sorted(set(d for d in deps if d != mod))
    dependencies[mod] = unique_deps

```

---

## Future enhancements

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
