terraform {
  backend "gcs" {
    bucket      = "serlo_production_terraform"
    prefix      = "state"
    credentials = "secrets/serlo-production-terraform-af6ce169abd8.json"
  }
}
