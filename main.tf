#####################################################################
# settings for production
#####################################################################
locals {
  domain  = "serlo.org"
  project = "serlo-production"

  credentials_path = "secrets/serlo-production-terraform-af6ce169abd8.json"
  service_account  = "terraform@serlo-production.iam.gserviceaccount.com"
  region           = "europe-west1"

  cluster_machine_type = "n1-highcpu-8"

  serlo_org_images = {
    server = {
      httpd             = "eu.gcr.io/serlo-shared/serlo-org-httpd:3.5.1"
      php               = "eu.gcr.io/serlo-shared/serlo-org-php:3.5.1"
      notifications_job = "eu.gcr.io/serlo-shared/serlo-org-notifications-job:1.0.2"
    }
    editor_renderer        = "eu.gcr.io/serlo-shared/serlo-org-legacy-editor-renderer:1.0.0"
    legacy_editor_renderer = "eu.gcr.io/serlo-shared/serlo-org-editor-renderer:2.0.9"
    varnish                = "eu.gcr.io/serlo-shared/varnish:6.0"
  }

  athene2_php_definitions-file_path = "secrets/athene2/definitions.production.php"

  athene2_database_instance_name = "${local.project}-mysql-instance-10072019-1"
  kpi_database_instance_name     = "${local.project}-postgres-instance-10072019-1"
}

#####################################################################
# providers
#####################################################################
provider "cloudflare" {
  version = "~> 2.0"
  email   = var.cloudflare_email
  api_key = var.cloudflare_token
}

provider "google" {
  version     = "~> 2.18"
  project     = "${local.project}"
  credentials = "${file("${local.credentials_path}")}"
}

provider "google-beta" {
  version     = "~> 2.18"
  project     = "${local.project}"
  credentials = "${file("${local.credentials_path}")}"
}

provider "helm" {
  version = "~> 0.10"
  kubernetes {
    host     = module.gcloud.host
    username = ""
    password = ""

    client_certificate     = base64decode(module.gcloud.client_certificate)
    client_key             = base64decode(module.gcloud.client_key)
    cluster_ca_certificate = base64decode(module.gcloud.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  version          = "~> 1.8"
  host             = "${module.gcloud.host}"
  load_config_file = false

  client_certificate     = base64decode(module.gcloud.client_certificate)
  client_key             = base64decode(module.gcloud.client_key)
  cluster_ca_certificate = base64decode(module.gcloud.cluster_ca_certificate)
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.1"
}

#####################################################################
# modules
#####################################################################
module "gcloud" {
  source                   = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud?ref=15666ddbd5b93c74c28781fec90a7b03b99b6377"
  project                  = local.project
  clustername              = "${local.project}-cluster"
  location                 = "europe-west1-b"
  region                   = local.region
  machine_type             = local.cluster_machine_type
  issue_client_certificate = true
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"

  providers = {
    google      = "google"
    google-beta = "google-beta"
  }
}

module "gcloud_mysql" {
  source                     = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_mysql?ref=15666ddbd5b93c74c28781fec90a7b03b99b6377"
  database_instance_name     = local.athene2_database_instance_name
  database_connection_name   = "${local.project}:${local.region}:${local.athene2_database_instance_name}"
  database_region            = local.region
  database_name              = "serlo"
  database_tier              = "db-n1-standard-4"
  database_private_network   = module.gcloud.network
  private_ip_address_range   = module.gcloud.private_ip_address_range
  database_password_default  = var.athene2_database_password_default
  database_password_readonly = var.athene2_database_password_readonly

  providers = {
    google      = "google"
    google-beta = "google-beta"
  }
}

module "gcloud_postgres" {
  source                   = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_postgres?ref=4834fc2bb1d4de1f89d06ecc6060d0e35da10b8e"
  database_instance_name   = local.kpi_database_instance_name
  database_connection_name = "${local.project}:${local.region}:${local.kpi_database_instance_name}"
  database_region          = local.region
  database_names           = ["kpi", "hydra"]
  database_private_network = module.gcloud.network
  private_ip_address_range = module.gcloud.private_ip_address_range

  database_password_postgres = var.kpi_kpi_database_password_postgres
  database_username_default  = module.kpi.kpi_database_username_default
  database_password_default  = var.kpi_kpi_database_password_default
  database_username_readonly = module.kpi.kpi_database_username_readonly
  database_password_readonly = var.kpi_kpi_database_password_readonly

  providers = {
    google      = "google"
    google-beta = "google-beta"
  }
}

module "serlo_org" {
  source = "github.com/serlo/infrastructure-modules-serlo.org.git//?ref=3dcd8f2f62ea316aa25c4938e1577bf923cf6d71"

  namespace         = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  image_pull_policy = "IfNotPresent"

  server = {
    app_replicas = 5
    images       = local.serlo_org_images.server

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
  }

  editor_renderer = {
    app_replicas = 2
    image        = local.serlo_org_images.editor_renderer
  }

  legacy_editor_renderer = {
    app_replicas = 2
    image        = local.serlo_org_images.legacy_editor_renderer
  }

  varnish = {
    app_replicas = 1
    image        = local.serlo_org_images.varnish
    memory       = "1G"
  }

  providers = {
    kubernetes = "kubernetes"
    random     = "random"
    template   = "template"
  }
}

module "athene2-dbdump" {
  source    = "github.com/serlo/infrastructure-modules-serlo.org.git//dbdump?ref=5a81003433cbb37ff7fd64220f3176470234a50c"
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

  providers = {
    kubernetes = "kubernetes"
    template   = "template"
  }
}

module "gcloud_dbdump_writer" {
  source = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_dbdump_writer?ref=15666ddbd5b93c74c28781fec90a7b03b99b6377"

  providers = {
    google = "google"
  }
}

module "kpi" {
  source = "github.com/serlo/infrastructure-modules-kpi.git//kpi?ref=v1.3.0"
  domain = local.domain

  grafana_admin_password = var.kpi_grafana_admin_password
  grafana_serlo_password = var.kpi_grafana_serlo_password

  athene2_database_host              = module.gcloud_mysql.database_private_ip_address
  athene2_database_password_readonly = var.athene2_database_password_readonly

  kpi_database_host              = module.gcloud_postgres.database_private_ip_address
  kpi_database_password_default  = var.kpi_kpi_database_password_default
  kpi_database_password_readonly = var.kpi_kpi_database_password_readonly

  grafana_image        = "eu.gcr.io/serlo-shared/kpi-grafana:1.0.1"
  mysql_importer_image = "eu.gcr.io/serlo-shared/kpi-mysql-importer:1.2.1"
  aggregator_image     = "eu.gcr.io/serlo-shared/kpi-aggregator:1.3.2"
}

module "ingress-nginx" {
  source      = "github.com/serlo/infrastructure-modules-shared.git//ingress-nginx?ref=51ec5b16d2d39171c88cf033ba3f7dcef22a0e9b"
  namespace   = kubernetes_namespace.ingress_nginx_namespace.metadata.0.name
  ip          = module.gcloud.staticip_regional_address
  domain      = "*.${local.domain}"
  nginx_image = "quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.24.1"

  providers = {
    kubernetes = "kubernetes"
    tls        = "tls"
  }
}

module "cloudflare" {
  source  = "github.com/serlo/infrastructure-modules-env-shared.git//cloudflare?ref=36d906c2b2a665836714babc9cdd7d4c7a2b5143"
  domain  = local.domain
  ip      = module.gcloud.staticip_regional_address
  zone_id = "1a4afa776acb2e40c3c8a135248328ae"

  providers = {
    cloudflare = "cloudflare"
  }
}

module "hydra" {
  source      = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=51ec5b16d2d39171c88cf033ba3f7dcef22a0e9b"
  dsn         = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/hydra"
  url_login   = "https://de.${local.domain}/auth/hydra/login"
  url_consent = "https://de.${local.domain}/auth/hydra/consent"
  host        = "hydra.${local.domain}"
  namespace   = kubernetes_namespace.hydra_namespace.metadata.0.name

  providers = {
    helm       = "helm"
    kubernetes = "kubernetes"
    random     = "random"
    template   = "template"
    tls        = "tls"
  }
}

module "rocket-chat" {
  source = "github.com/serlo/infrastructure-modules-shared.git//rocket-chat?ref=603e5f01190f19ab47f1fa13f40f4e053b962c1e"

  host      = "community.${local.domain}"
  namespace = kubernetes_namespace.community_namespace.metadata.0.name
  image_tag = "2.2.1"

  mongodump = {
    image         = "eu.gcr.io/serlo-shared/mongodb-tools-base:1.0.1"
    schedule      = "0 0 * * *"
    bucket_prefix = local.project
  }

  smtp_password = var.athene2_php_smtp_password

  providers = {
    google   = "google"
    helm     = "helm"
    random   = "random"
    template = "template"
  }
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
