#####################################################################
# settings for production
#####################################################################
locals {
  domain  = "serlo.org"
  project = "serlo-production"

  credentials_path = "secrets/serlo-production-terraform-af6ce169abd8.json"
  service_account  = "terraform@serlo-production.iam.gserviceaccount.com"

  region = "europe-west3"
  zone   = "europe-west3-a"

  cluster_machine_type = "n1-highcpu-4"

  serlo_org_image_tags = {
    server = {
      httpd             = "5.2.6"
      php               = "5.2.6"
      notifications_job = "2.0.1"
    }
    editor_renderer        = "4.0.5"
    legacy_editor_renderer = "2.0.0"
    frontend               = "2.0.9"
  }
  varnish_image = "eu.gcr.io/serlo-shared/varnish:6.0"

  athene2_php_definitions-file_path = "secrets/athene2/definitions.production.php"

  athene2_database_instance_name = "${local.project}-mysql-2020-01-26"
  kpi_database_instance_name     = "${local.project}-postgres-2020-01-26"
}

#####################################################################
# modules
#####################################################################
module "cluster" {
  source   = "github.com/serlo/infrastructure-modules-gcloud.git//cluster?ref=eac9c2757582cc3483310fa8649fa43904cb3c6b"
  name     = "${local.project}-cluster"
  location = local.zone
  region   = local.region

  node_pool = {
    machine_type       = local.cluster_machine_type
    preemptible        = false
    initial_node_count = 2
    min_node_count     = 2
    max_node_count     = 10
  }
}

module "gcloud_mysql" {
  source                     = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_mysql?ref=eac9c2757582cc3483310fa8649fa43904cb3c6b"
  database_instance_name     = local.athene2_database_instance_name
  database_connection_name   = "${local.project}:${local.region}:${local.athene2_database_instance_name}"
  database_region            = local.region
  database_name              = "serlo"
  database_tier              = "db-n1-standard-4"
  database_private_network   = module.cluster.network
  database_password_default  = var.athene2_database_password_default
  database_password_readonly = var.athene2_database_password_readonly
}

module "gcloud_postgres" {
  source                   = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_postgres?ref=eac9c2757582cc3483310fa8649fa43904cb3c6b"
  database_instance_name   = local.kpi_database_instance_name
  database_connection_name = "${local.project}:${local.region}:${local.kpi_database_instance_name}"
  database_region          = local.region
  database_names           = ["kpi", "hydra"]
  database_private_network = module.cluster.network

  database_password_postgres = var.kpi_kpi_database_password_postgres
  database_username_default  = module.kpi.kpi_database_username_default
  database_password_default  = var.kpi_kpi_database_password_default
  database_username_readonly = module.kpi.kpi_database_username_readonly
  database_password_readonly = var.kpi_kpi_database_password_readonly
}

module "serlo_org" {
  source = "github.com/serlo/infrastructure-modules-serlo.org.git//?ref=40f6359ed6f0667fe14a651f8e4ba45a0d4066ba"

  namespace         = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  image_pull_policy = "IfNotPresent"

  server = {
    app_replicas = 5
    image_tags   = local.serlo_org_image_tags.server

    domain                = local.domain
    definitions_file_path = local.athene2_php_definitions-file_path

    resources = {
      httpd = {
        limits = {
          cpu    = "400m"
          memory = "500Mi"
        }
        requests = {
          cpu    = "250m"
          memory = "200Mi"
        }
      }
      php = {
        limits = {
          cpu    = "2000m"
          memory = "500Mi"
        }
        requests = {
          cpu    = "250m"
          memory = "200Mi"
        }
      }
    }

    recaptcha = {
      key    = var.athene2_php_recaptcha_key
      secret = var.athene2_php_recaptcha_secret
    }

    smtp_password = var.athene2_php_smtp_password
    mailchimp_key = var.athene2_php_newsletter_key

    enable_tracking   = true
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
    redis_hosts     = "['redis-master.redis']"
  }

  editor_renderer = {
    app_replicas = 2
    image_tag    = local.serlo_org_image_tags.editor_renderer
  }

  legacy_editor_renderer = {
    app_replicas = 2
    image_tag    = local.serlo_org_image_tags.legacy_editor_renderer
  }

  frontend = {
    app_replicas = 2
    image_tag    = local.serlo_org_image_tags.frontend
  }

  varnish = {
    app_replicas = 1
    image        = local.varnish_image
    memory       = "1G"
  }
}

module "athene2-dbdump" {
  source    = "github.com/serlo/infrastructure-modules-serlo.org.git//dbdump?ref=40f6359ed6f0667fe14a651f8e4ba45a0d4066ba"
  image     = "eu.gcr.io/serlo-shared/athene2-dbdump-cronjob:2.0.0"
  namespace = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  schedule  = "0 0 * * *"
  database = {
    host     = module.gcloud_mysql.database_private_ip_address
    port     = "3306"
    username = "serlo_readonly"
    password = var.athene2_database_password_readonly
    name     = "serlo"
  }

  bucket = {
    url                 = "gs://anonymous-data"
    service_account_key = module.gcloud_dbdump_writer.account_key
  }
}

module "gcloud_dbdump_writer" {
  source = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_dbdump_writer?ref=eac9c2757582cc3483310fa8649fa43904cb3c6b"
}

module "kpi" {
  source = "github.com/serlo/infrastructure-modules-kpi.git//kpi?ref=v1.3.1"
  domain = local.domain

  grafana_admin_password = var.kpi_grafana_admin_password
  grafana_serlo_password = var.kpi_grafana_serlo_password

  athene2_database_host              = module.gcloud_mysql.database_private_ip_address
  athene2_database_password_readonly = var.athene2_database_password_readonly

  kpi_database_host              = module.gcloud_postgres.database_private_ip_address
  kpi_database_password_default  = var.kpi_kpi_database_password_default
  kpi_database_password_readonly = var.kpi_kpi_database_password_readonly

  grafana_image        = "eu.gcr.io/serlo-shared/kpi-grafana:1.2.0"
  mysql_importer_image = "eu.gcr.io/serlo-shared/kpi-mysql-importer:1.3.3"
  aggregator_image     = "eu.gcr.io/serlo-shared/kpi-aggregator:1.5.0"
}

module "ingress-nginx" {
  source      = "github.com/serlo/infrastructure-modules-shared.git//ingress-nginx?ref=0a60181e6fc2c1001ec267dec1cd4382a054399a"
  namespace   = kubernetes_namespace.ingress_nginx_namespace.metadata.0.name
  ip          = module.cluster.address
  domain      = "*.${local.domain}"
  nginx_image = "quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.24.1"
}

module "cloudflare" {
  source  = "github.com/serlo/infrastructure-modules-env-shared.git//cloudflare?ref=b5dbab5bfd6187f797066a8c74a795bc7d21cef5"
  domain  = local.domain
  ip      = module.cluster.address
  zone_id = "1a4afa776acb2e40c3c8a135248328ae"
}

module "hydra" {
  source      = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=0a60181e6fc2c1001ec267dec1cd4382a054399a"
  dsn         = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/hydra"
  url_login   = "https://de.${local.domain}/auth/hydra/login"
  url_consent = "https://de.${local.domain}/auth/hydra/consent"
  host        = "hydra.${local.domain}"
  namespace   = kubernetes_namespace.hydra_namespace.metadata.0.name
}

module "redis" {
  source = "github.com/serlo/infrastructure-modules-shared.git//redis?ref=0a60181e6fc2c1001ec267dec1cd4382a054399a"

  namespace = kubernetes_namespace.redis_namespace.metadata.0.name
  image_tag = "5.0.7-debian-9-r12"
}

module "rocket-chat" {
  source = "github.com/serlo/infrastructure-modules-shared.git//rocket-chat?ref=0a60181e6fc2c1001ec267dec1cd4382a054399a"

  host      = "community.${local.domain}"
  namespace = kubernetes_namespace.community_namespace.metadata.0.name
  image_tag = "2.2.1"

  mongodump = {
    image         = "eu.gcr.io/serlo-shared/mongodb-tools-base:1.0.1"
    schedule      = "0 0 * * *"
    bucket_prefix = local.project
  }

  smtp_password = var.athene2_php_smtp_password
}

#####################################################################
# ingress
#####################################################################
resource "kubernetes_ingress" "kpi_ingress" {
  metadata {
    name      = "kpi-ingress"
    namespace = kubernetes_namespace.kpi_namespace.metadata.0.name

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "stats.${local.domain}"

      http {
        path {
          path = "/"

          backend {
            service_name = module.kpi.grafana_service_name
            service_port = module.kpi.grafana_service_port
          }
        }
      }
    }
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

#####################################################################
# namespaces
#####################################################################
resource "kubernetes_namespace" "serlo_org_namespace" {
  metadata {
    name = "serlo-org"
  }
}

resource "kubernetes_namespace" "kpi_namespace" {
  metadata {
    name = "kpi"
  }
}

resource "kubernetes_namespace" "community_namespace" {
  metadata {
    name = "community"
  }
}

resource "kubernetes_namespace" "hydra_namespace" {
  metadata {
    name = "hydra"
  }
}

resource "kubernetes_namespace" "ingress_nginx_namespace" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "redis_namespace" {
  metadata {
    name = "redis"
  }
}
