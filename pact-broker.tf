module "pact_broker" {
  source = "github.com/serlo/infrastructure-modules-shared.git//pact-broker?ref=3150640383eebf21c68fb27bd02b86baaf85757d"

  namespace         = kubernetes_namespace.pact_broker_namespace.metadata.0.name
  image_tag         = "2.50.1-1"
  image_pull_policy = "IfNotPresent"
  database = {
    host     = module.gcloud_postgres.database_private_ip_address
    name     = "pact-broker"
    username = module.kpi.kpi_database_username_default
    password = var.kpi_kpi_database_password_default
  }
}

module "pact_broker_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=c41476e253475fa2eacbada4228074dd6d7df58f"

  name      = "pact-broker"
  namespace = kubernetes_namespace.pact_broker_namespace.metadata.0.name
  host      = "pacts.${local.domain}"
  backend = {
    service_name = module.pact_broker.service_name
    service_port = module.pact_broker.service_port
  }
  enable_tls = true
}

resource "kubernetes_namespace" "pact_broker_namespace" {
  metadata {
    name = "pact-broker"
  }
}
