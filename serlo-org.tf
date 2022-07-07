locals {
  serlo_org = {
    image_tags = {
      server = {
        httpd             = "19.2.1"
        php               = "19.2.1"
        migrate           = "19.2.1"
        notifications_job = "3.0.5"
      }
      editor_renderer        = "13.4.4"
      legacy_editor_renderer = "3.0.4"
      varnish                = "6.0.2"
    }
  }
}

module "serlo_org" {
  source = "github.com/serlo/infrastructure-modules-serlo.org.git//?ref=v5.0.0"

  namespace         = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  image_pull_policy = "IfNotPresent"
  node_pool         = module.cluster.node_pools.non-preemptible

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
      host     = module.mysql.database_private_ip_address
      username = "serlo"
      password = var.athene2_database_password_default
    }

    database_readonly = {
      username = "serlo_readonly"
      password = var.athene2_database_password_readonly
    }

    upload_secret                = file("secrets/serlo-org-6bab84a1b1a5.json")
    hydra_admin_uri              = module.hydra.admin_uri
    feature_flags                = "[]"
    autoreview_taxonomy_term_ids = "[106082]"

    api = {
      host   = module.api.server_host
      secret = module.api.secrets_serlo_org
    }

    enable_tracking_hotjar           = false
    enable_tracking_google_analytics = false
    enable_tracking_simple_analytics = true
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

    annotations = {
      "kubernetes.io/ingress.class"                 = "nginx"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "2M"
    }
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
