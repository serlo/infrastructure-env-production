locals {
  notification_mail = {
    image_tag = "0.1.3"
  }
}

module "notifications" {
  source = "github.com/serlo/infrastructure-modules-shared.git//notification-mail?ref=v15.4.0"

  namespace = kubernetes_namespace.notifications.metadata.0.name
  image_tag = local.notification_mail.image_tag
  node_pool = module.cluster.node_pools.non-preemptible

  api_graphql_url = "https://api.${local.domain}/graphql"
  db_uri          = "mysql://serlo:${var.athene2_database_password_default}@${module.mysql.database_private_ip_address}:3306/serlo"
  smtp_uri        = "smtp://SMTP_Injection:${var.athene2_php_smtp_password}@smtp.eu.sparkpostmail.com:2525"
}

resource "kubernetes_namespace" "notifications" {
  metadata {
    name = "notifications"
  }
}
