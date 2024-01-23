locals {
  mfnf2serlo_image_tag = "0.5"
}

module "mfnf2serlo" {
  source = "github.com/serlo/infrastructure-modules-shared.git//mfnf2serlo?ref=v17.8.0"

  namespace = kubernetes_namespace.mfnf_namespace.metadata.0.name

  node_pool = module.cluster.node_pools.non-preemptible

  image_tag = local.mfnf2serlo_image_tag
}

module "mfnf2serlo_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v13.2.0"

  name      = "mfnf"
  namespace = kubernetes_namespace.mfnf_namespace.metadata.0.name

  host = "mfnf.${local.domain}"
  backend = {
    service_name = module.mfnf2serlo.mfnf2serlo_service_name
    service_port = module.mfnf2serlo.mfnf2serlo_service_port
  }
  enable_tls  = true
  enable_cors = true
}

resource "kubernetes_namespace" "mfnf_namespace" {
  metadata {
    name = "mfnf"
  }
}
