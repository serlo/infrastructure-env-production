provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "google" {
  project     = local.project
  credentials = file(local.credentials_path)
}

provider "google-beta" {
  project     = local.project
  credentials = file(local.credentials_path)
}

provider "helm" {
  kubernetes {
    host     = module.cluster.endpoint
    username = ""
    password = ""

    client_certificate     = base64decode(module.cluster.auth.client_certificate)
    client_key             = base64decode(module.cluster.auth.client_key)
    cluster_ca_certificate = base64decode(module.cluster.auth.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host             = module.cluster.endpoint
  load_config_file = false

  client_certificate     = base64decode(module.cluster.auth.client_certificate)
  client_key             = base64decode(module.cluster.auth.client_key)
  cluster_ca_certificate = base64decode(module.cluster.auth.cluster_ca_certificate)
}
