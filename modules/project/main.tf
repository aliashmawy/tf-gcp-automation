resource "google_project" "project" {
  name       = var.project_id
  project_id = var.project_id
  labels     = var.labels
  billing_account = var.billing_account
}

resource "google_project_service" "enabled_apis" {
  for_each = toset(var.apis)
  project  = google_project.project.project_id
  service  = each.value
}
output "project_id" {
  value = google_project.project.project_id
}
