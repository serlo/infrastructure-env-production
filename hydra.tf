locals {
  hydra = {
    chart_version = "0.4.13"
    image_tag     = "v1.8.5"
  }
}

module "hydra" {
  source = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=v2.0.0"

  namespace     = kubernetes_namespace.hydra_namespace.metadata.0.name
  dsn           = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/hydra"
  url_login     = "https://de.${local.domain}/auth/hydra/login"
  url_logout    = "https://de.${local.domain}/auth/hydra/logout"
  url_consent   = "https://de.${local.domain}/auth/hydra/consent"
  host          = "hydra.${local.domain}"
  chart_version = local.hydra.chart_version
  image_tag     = local.hydra.image_tag
}

resource "kubernetes_namespace" "hydra_namespace" {
  metadata {
    name = "hydra"
  }
}
