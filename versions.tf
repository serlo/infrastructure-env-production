terraform {
  required_version = ">= 0.13"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.13.2"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.48.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "3.48.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.2"
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
