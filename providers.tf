provider "cloudflare" {
  version   = "2.3.0"
  api_token = var.cloudflare_token
}

provider "google" {
  version     = "3.5.0"
  project     = local.project
  credentials = file(local.credentials_path)
}

provider "google-beta" {
  version     = "3.5.0"
  project     = local.project
  credentials = file(local.credentials_path)
}

provider "helm" {
  version = "0.10.4"
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
  version          = "1.10.0"
  host             = module.cluster.endpoint
  load_config_file = false

  client_certificate     = base64decode(module.cluster.auth.client_certificate)
  client_key             = base64decode(module.cluster.auth.client_key)
  cluster_ca_certificate = base64decode(module.cluster.auth.cluster_ca_certificate)
}

provider "null" {
  version = "2.1.2"
}

provider "random" {
  version = "2.2.1"
}

provider "template" {
  version = "2.1.2"
}

provider "tls" {
  version = "2.1.1"
}