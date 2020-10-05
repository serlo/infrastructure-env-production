locals {
  rocket_chat = {
    chart_version = "2.0.6"
    image_tag     = "3.7.0"
  }
}

module "rocket-chat" {
  source = "github.com/serlo/infrastructure-modules-shared.git//rocket-chat?ref=9b7a486cf487a79069e4a0c7806de0666f78a0c4"

  host          = "community.${local.domain}"
  namespace     = kubernetes_namespace.community_namespace.metadata.0.name
  chart_version = local.rocket_chat.chart_version
  image_tag     = local.rocket_chat.image_tag
  app_replicas  = 2

  mongodump = {
    image         = "eu.gcr.io/serlo-shared/mongodb-tools-base:1.0.1"
    schedule      = "0 0 * * *"
    bucket_prefix = local.project
  }

  smtp_password = var.athene2_php_smtp_password
}

resource "kubernetes_namespace" "community_namespace" {
  metadata {
    name = "community"
  }
}
