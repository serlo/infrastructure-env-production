locals {
  redis = {
    chart_version = "10.4.1"
    image_tag     = "5.0.7-debian-9-r12"
  }
}

module "redis" {
  source = "github.com/serlo/infrastructure-modules-shared.git//redis?ref=09d5816564693345a8882d5606a8d59024d81905"

  namespace     = kubernetes_namespace.redis_namespace.metadata.0.name
  chart_version = local.redis.chart_version
  image_tag     = local.redis.image_tag
}

resource "kubernetes_namespace" "redis_namespace" {
  metadata {
    name = "redis"
  }
}
