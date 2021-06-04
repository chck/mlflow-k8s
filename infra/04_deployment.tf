variable "deployment" {
  type = map(string)
  default = {
    ksa_name      = "mlflow"
    k8s_namespace = "default"
  }
}

# Retrieve an access token as the Terraform runner
data "google_client_config" "provider" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_service_account" "ksa" {
  depends_on = [
    google_service_account.sa,
  ]
  metadata {
    name = var.deployment.ksa_name
    annotations = {
      "iam.gke.io/gcp-service-account" = "${google_service_account.sa.account_id}@${var.common.project}.iam.gserviceaccount.com"
    }
  }
}

resource "kubernetes_deployment" "mlflow" {
  for_each = local.users
  depends_on = [
    google_container_cluster.primary,
    kubectl_manifest.backend_config,
    kubernetes_service.internal,
  ]
  metadata {
    name = "mlflow-${each.value}"
  }
  spec {
    selector {
      match_labels = {
        tier = "mlflow-${each.value}"
      }
    }
    template {
      metadata {
        labels = {
          tier = "mlflow-${each.value}"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.ksa.metadata[0].name
        node_selector = {
          "iam.gke.io/gke-metadata-server-enabled" = "true"
          "cloud.google.com/gke-nodepool"          = google_container_node_pool.preemptible_nodes.name
        }
        container {
          name  = "mlflow"
          image = "chck/mlflow:1.17.1-patch1"
          args = [
            "--static-prefix=/${each.value}",
            "--backend-store-uri=postgresql://$(DB_USER):$(DB_PASS)@$(DB_HOST)/u_${each.value}",
            "--default-artifact-root=gs://${google_storage_bucket.artifact.name}/${each.value}/mlruns",
            "--gunicorn-opts=--worker-class=gevent --access-logfile=- --timeout=180 --log-level=debug",
          ]
          port {
            container_port = 5000
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.mlflow_secret.metadata[0].name
            }
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
          }
        }
        container {
          name    = "cloud-sql-proxy"
          image   = "gcr.io/cloudsql-docker/gce-proxy:1.22.0-alpine"
          command = ["/cloud_sql_proxy", "-instances=${var.common.project}:${var.common.region}:${var.database.instance_name}=tcp:5432"]
          security_context {
            run_as_non_root = true
          }
        }
      }
    }
  }
}
