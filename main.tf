module "project" {
  source           = "./modules/project"
  project_id       = "dev-intern-poc"
  billing_account  = "XXXXXX-XXXXXX-XXXXXX"
  labels           = { owner = "intern", environment = "test" }
  apis             = ["compute.googleapis.com", "iam.googleapis.com"]
}
