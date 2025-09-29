resource "google_project" "my_project" {
  name       = var.project_name
  project_id = var.project_id
  billing_account = data.google_billing_account.acct.id
}
data "google_billing_account" "acct" {
  display_name = "My Billing Account"
  open         = true
}

resource "google_project_service" "required" {
  for_each = toset(var.enabled_apis)

  project             = var.project_id
  service             = each.value
  disable_on_destroy  = false
}