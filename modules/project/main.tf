module "network" {
  source          = "../network"
  vpc_name        = "${var.project_name}-network"
  subnet1_name    = "${var.project_name}-subnet"
  ip_cidr_range   = var.ip_cidr_range
  region          = var.region
  project_id      = var.project_id
}

resource "google_project" "my_project" {
  name       = var.project_name
  project_id = var.project_id
  labels     = var.labels
  billing_account = var.billing_account
  deletion_policy = "DELETE"
}

resource "google_project_service" "required" {
  for_each = toset(var.enabled_apis)
  project  = google_project.my_project.project_id
  service  = each.key
}
