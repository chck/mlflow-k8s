terraform {
  required_version = "~> 0.15.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.67.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.67.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.10.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.12.1"
    }
  }

  backend "gcs" {
    bucket = "_YOUR_BUCKET"
    prefix = "mlflow-k8s"
  }
}

variable "common" {
  type = map(string)
  default = {
    project = "_YOUR_PROJECT"
    region  = "asia-northeast1"
    zone    = "asia-northeast1-c"
  }
}

locals {
  common = var.common
  users  = var.users
}

variable "users" {
  type = set(string)
  default = [
    "user1", "user2", "projectz",
  ]
}

provider "google-beta" {
  project = local.common.project
}

provider "google" {
  project = local.common.project
}
