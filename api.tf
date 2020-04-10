locals {
  api = {
    image_tag = "0.1.1"
  }
}

module "api_secrets" {
  source = "github.com/serlo/infrastructure-modules-api.git//secrets?ref=a4c13d2bb16b28c4258a0ce4c035b23f5a54fa43"
}

module "api_server" {
  source = "github.com/serlo/infrastructure-modules-api.git//server?ref=a4c13d2bb16b28c4258a0ce4c035b23f5a54fa43"

  namespace         = kubernetes_namespace.api_namespace.metadata.0.name
  image_tag         = local.api.image_tag
  image_pull_policy = "IfNotPresent"

  secrets              = module.api_secrets
  serlo_org_ip_address = module.serlo_org.server_service_ip_address
}

module "api_server_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=c41476e253475fa2eacbada4228074dd6d7df58f"

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
