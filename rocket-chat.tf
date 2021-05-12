locals {
  rocket_chat = {
    chart_versions = {
      rocketchat = "2.0.10"
      mongodb    = "10.4.0"
    }
    image_tags = {
      rocketchat = "3.11.5"
      mongodb    = "4.2.11"
    }
  }
}

module "rocket-chat" {
  source = "github.com/serlo/infrastructure-modules-shared.git//rocket-chat?ref=v3.0.4"

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
