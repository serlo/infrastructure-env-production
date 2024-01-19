locals {
  kpi = {
    grafana_image_tag        = "1.6.2"
    mysql_importer_image_tag = "1.4.1"
    aggregator_image_tag     = "1.7.1"
    mfnf_importer_image_tag  = "1.0.1"
  }

  mfnf2serlo_image_tag = "0.5"
}

module "mfnf2serlo" {
  source = "github.com/serlo/infrastructure-modules-kpi.git//mfnf2serlo?ref=v6.1.1"

  namespace = kubernetes_namespace.kpi_namespace.metadata.0.name

  node_pool = module.cluster.node_pools.non-preemptible

  image_tag = local.mfnf2serlo_image_tag
}

module "mfnf2serlo_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v13.2.0"

  name      = "mfnf"
  namespace = kubernetes_namespace.kpi_namespace.metadata.0.name

  host = "mfnf.${local.domain}"
  backend = {
    service_name = module.mfnf2serlo.mfnf2serlo_service_name
    service_port = module.mfnf2serlo.mfnf2serlo_service_port
  }
  enable_tls  = true
  enable_cors = true
}

resource "kubernetes_namespace" "kpi_namespace" {
  metadata {
    name = "kpi"
  }
}
