locals {
  serlo_org = {
    image_tags = {
      server = {
        httpd             = "11.0.0"
        php               = "11.0.0"
        migrate           = "11.0.0"
        notifications_job = "2.1.0"
      }
      editor_renderer        = "8.1.0"
      legacy_editor_renderer = "2.1.0"
      varnish                = "6.0.2"
    }
  }
}

module "serlo_org" {
  source = "github.com/serlo/infrastructure-modules-serlo.org.git//?ref=e1f7e2942ab2bc4a8307f0e67985f4bed0692162"

  namespace         = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  image_pull_policy = "IfNotPresent"

  server = {
    image_tags = local.serlo_org.image_tags.server

    domain = local.domain

    recaptcha = {
      key    = var.athene2_php_recaptcha_key
      secret = var.athene2_php_recaptcha_secret
    }

    smtp_password = var.athene2_php_smtp_password
    mailchimp_key = var.athene2_php_newsletter_key

    enable_basic_auth = false
    enable_cronjobs   = true
    enable_mail_mock  = false

    database = {
      host     = module.gcloud_mysql.database_private_ip_address
      username = "serlo"
      password = var.athene2_database_password_default
    }

    database_readonly = {
      username = "serlo_readonly"
      password = var.athene2_database_password_readonly
    }

    upload_secret   = file("secrets/serlo-org-6bab84a1b1a5.json")
    hydra_admin_uri = module.hydra.admin_uri
    feature_flags   = "[]"

    api = {
      host   = module.api_server.host
      secret = module.api_secrets.serlo_org
    }

    enable_tracking_hotjar           = true
    enable_tracking_google_analytics = true
    enable_tracking_matomo           = false
    matomo_tracking_domain           = "analytics.${local.domain}"
  }

  editor_renderer = {
    image_tag = local.serlo_org.image_tags.editor_renderer
  }

  legacy_editor_renderer = {
    image_tag = local.serlo_org.image_tags.legacy_editor_renderer
  }

  varnish = {
    image_tag = local.serlo_org.image_tags.varnish
  }
}

resource "kubernetes_ingress" "athene2_ingress" {
  metadata {
    name      = "athene2-ingress"
    namespace = kubernetes_namespace.serlo_org_namespace.metadata.0.name

    annotations = { "kubernetes.io/ingress.class" = "nginx" }
  }

  spec {
    backend {
      service_name = module.serlo_org.service_name
      service_port = module.serlo_org.service_port
    }
  }
}

resource "kubernetes_namespace" "serlo_org_namespace" {
  metadata {
    name = "serlo-org"
  }
}
