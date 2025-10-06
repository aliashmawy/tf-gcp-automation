resource "google_service_account" "cloudrun" {
  account_id   = var.service_account_id
  display_name = var.display_name
  project      = var.project_id
}

# Attach roles to the service account
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(var.cloudrun_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}