locals {
  rocket_chat = {
    chart_versions = {
      rocketchat = "3.1.0"
      mongodb    = "10.23.13"
    }
    image_tags = {
      rocketchat = "3.16.5"
      mongodb    = "4.4.8"
    }
  }
}

module "rocket-chat" {
  source = "github.com/serlo/infrastructure-modules-shared.git//rocket-chat?ref=v8.0.0"

  host           = "community.${local.domain}"
  namespace      = kubernetes_namespace.community_namespace.metadata.0.name
  chart_versions = local.rocket_chat.chart_versions
  image_tags     = local.rocket_chat.image_tags
  app_replicas   = 1

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
