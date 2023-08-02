locals {
  rocket_chat = {
    chart_versions = {
      rocketchat = "4.7.4"
      mongodb    = "10.23.13"
    }
    image_tags = {
      rocketchat = "3.18.7"
      mongodb    = "4.4.8"
    }
  }
}

module "rocket-chat" {
  source = "github.com/serlo/infrastructure-modules-shared.git//rocket-chat?ref=v17.1.1"

  host           = "community.${local.domain}"
  namespace      = kubernetes_namespace.community_namespace.metadata.0.name
  chart_versions = local.rocket_chat.chart_versions
  image_tags     = local.rocket_chat.image_tags
  node_pool      = module.cluster.node_pools.non-preemptible

  app_replicas = 1

  mongodump = {
    image         = "eu.gcr.io/serlo-shared/mongodb-tools-base:1.0.1"
    schedule      = "0 0 * * *"
    bucket_prefix = local.project
  }

  smtp_password = var.athene2_php_smtp_password
}

module "rocket-chat_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v13.1.0"

  name      = "rocket-chat"
  namespace = kubernetes_namespace.community_namespace.metadata.0.name
  host      = "community.${local.domain}"
  backend = {
    service_name = "rocket-chat-rocketchat"
    service_port = 80
  }
  enable_tls = true
}

resource "kubernetes_namespace" "community_namespace" {
  metadata {
    name = "community"
  }
}
