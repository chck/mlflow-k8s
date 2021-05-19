variable "network" {
  type = map(string)
  default = {
    certificate_name = "mlflow-k8s-cert"
    domain_name      = "_YOUR_MLFLOW_DOMAIN"
    zone_name        = "mlflow-k8s"
  }
}

resource "google_compute_global_address" "mlflow_ip" {
  name = "mlflow-k8s-ip"
}

resource "kubernetes_service" "internal" {
  for_each = local.users
  depends_on = [
    google_container_cluster.primary,
  ]
  metadata {
    name = "service-${each.value}"
    annotations = {
      "beta.cloud.google.com/backend-config" = jsonencode(tomap({ "${var.deployment.k8s_namespace}" = var.iap.backend_config_name }))
    }
  }
  spec {
    type = "NodePort"
    selector = {
      tier = "mlflow-${each.value}"
    }
    port {
      port        = 5000
      target_port = 5000
    }
  }
}

resource "kubernetes_ingress" "mlflow" {
  depends_on = [
    google_container_cluster.primary,
    google_compute_global_address.mlflow_ip,
    kubectl_manifest.managed_certificate,
  ]
  metadata {
    name = "mlflow-ingress"
    annotations = {
      "kubernetes.io/ingress.allow-http"            = "false"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.mlflow_ip.name
      "networking.gke.io/managed-certificates"      = var.network.certificate_name
      #      "nginx.ingress.kubernetes.io/rewrite-target"  = "/"
    }
  }
  spec {
    rule {
      http {
        dynamic "path" {
          for_each = local.users
          content {
            path = "/${path.value}"
            backend {
              service_name = "service-${path.value}"
              service_port = 5000
            }
          }
        }
        dynamic "path" {
          for_each = local.users
          content {
            path = "/${path.value}/*"
            backend {
              service_name = "service-${path.value}"
              service_port = 5000
            }
          }
        }
      }
    }
  }
}

resource "google_dns_managed_zone" "mlflow" {
  name        = var.network.zone_name
  dns_name    = "${var.network.domain_name}."
  description = "for MLflow to track your experiments"
}
resource "google_dns_record_set" "mlflow" {
  name         = google_dns_managed_zone.mlflow.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.mlflow.name
  rrdatas      = [google_compute_global_address.mlflow_ip.address]
}

data "kubectl_path_documents" "managed_certificate" {
  pattern = "./manifests/managed_certificate.yaml"
  vars = {
    certificate_name = var.network.certificate_name
    domain_name      = var.network.domain_name
  }
}
resource "kubectl_manifest" "managed_certificate" {
  depends_on = [
    google_container_cluster.primary,
  ]
  count     = length(data.kubectl_path_documents.managed_certificate.documents)
  yaml_body = element(data.kubectl_path_documents.managed_certificate.documents, count.index)
}

output "mlflow_global_ip" {
  value = google_compute_global_address.mlflow_ip.address
}
