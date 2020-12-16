terraform {
  required_version = ">= 0.13"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.14.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.51.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "3.51.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "2.1.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "2.2.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.1.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "2.1.1"
    }
  }
}
