locals {
  api = {
    image_tags = {
      database_layer = "0.1.6"
      server         = "0.17.7"
    }
  }
}

module "api_redis" {
  source = "github.com/serlo/infrastructure-modules-shared.git//redis?ref=v3.0.2"

  namespace     = kubernetes_namespace.api_namespace.metadata.0.name
  chart_version = "12.6.2"
  image_tag     = "6.0.10"
}

module "api" {
  source = "github.com/serlo/infrastructure-modules-api.git//?ref=v4.1.2"

  namespace         = kubernetes_namespace.api_namespace.metadata.0.name
  image_tag         = local.api.image_tags.server
  image_pull_policy = "IfNotPresent"

  environment = "production"
  google_spreadsheet_api = {
    active_donors = var.api_active_donors_google_spreadsheet_id
    secret        = var.api_active_donors_google_api_key
  }
  redis_url            = "redis://redis-master:6379"
  sentry_dsn           = "https://dd6355782e894e048723194b237baa39@o115070.ingest.sentry.io/5385534"
  serlo_org_ip_address = module.serlo_org.server_service_ip_address

  database_layer = {
    image_tag = local.api.image_tags.database_layer

    database_url             = "mysql://serlo_readonly:${var.athene2_database_password_readonly}@${module.gcloud_mysql.database_private_ip_address}:3306/serlo"
    database_max_connections = 50
  }

  server = {
    hydra_host = module.hydra.admin_uri
    swr_queue_dashboard = {
      username = var.api_swr_queue_dashboard_username
      password = var.api_swr_queue_dashboard_password
    }
  }

  swr_queue_worker = {
    concurrency = 2
  }
}

module "api_server_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v2.0.0"

  name      = "api"
  namespace = kubernetes_namespace.api_namespace.metadata.0.name
  host      = "api.${local.domain}"
  backend = {
    service_name = module.api.server_service_name
    service_port = module.api.server_service_port
  }
  enable_tls = true
}

resource "kubernetes_namespace" "api_namespace" {
  metadata {
    name = "api"
  }
}
