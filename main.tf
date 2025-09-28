provider "google" {
  region      = "us-central1"
}

module "project" {
  source          = "./modules/project"
  project_id      = "tf-automation-by-ali-and-besho"
}