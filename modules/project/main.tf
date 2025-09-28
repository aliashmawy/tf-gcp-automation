resource "google_project" "my_project" {
  name       = var.project_name
  project_id = var.project_id
  billing_account = data.google_billing_account.acct.id
  deletion_policy = "DELETE"
}
data "google_billing_account" "acct" {
  display_name = "My Billing Account"
  open         = true
}