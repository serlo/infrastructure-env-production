locals {
  api = {
    image_tag = "0.13.1"
  }
}

module "api_redis" {
  source = "github.com/serlo/infrastructure-modules-shared.git//redis?ref=v2.0.0"

  namespace     = kubernetes_namespace.api_namespace.metadata.0.name
  chart_version = "10.9.0"
  image_tag     = "6.0.9"
}

module "api_secrets" {
  source = "github.com/serlo/infrastructure-modules-api.git//secrets?ref=v1.0.0"
}

module "api_server" {
  source = "github.com/serlo/infrastructure-modules-api.git//server?ref=v1.0.0"

  namespace         = kubernetes_namespace.api_namespace.metadata.0.name
  image_tag         = local.api.image_tag
  image_pull_policy = "IfNotPresent"

  secrets              = module.api_secrets
  redis_url            = "redis://redis-master:6379"
  hydra_host           = module.hydra.admin_uri
  serlo_org_ip_address = module.serlo_org.server_service_ip_address

  active_donors_data = {
    google_api_key        = var.api_active_donors_google_api_key
    google_spreadsheet_id = var.api_active_donors_google_spreadsheet_id
  }

  sentry_dsn         = "https://dd6355782e894e048723194b237baa39@o115070.ingest.sentry.io/5385534"
  sentry_environment = "production"
}

module "api_server_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v2.0.0"

  name      = "api"
  namespace = kubernetes_namespace.api_namespace.metadata.0.name
  host      = "api.${local.domain}"
  backend = {
    service_name = module.api_server.service_name
    service_port = module.api_server.service_port
  }
  enable_tls = true
}

resource "kubernetes_namespace" "api_namespace" {
  metadata {
    name = "api"
  }
}
