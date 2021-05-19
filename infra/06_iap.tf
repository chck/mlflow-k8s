variable "iap" {
  type = map(string)
  default = {
    secret_name         = "iap-secret"
    backend_config_name = "iap-backend-config"
  }
}

data "local_file" "client_secret" {
  filename = "./secrets/oauth_client_secret.json"
}

resource "kubernetes_secret" "iap_secret" {
  metadata {
    name = var.iap.secret_name
  }
  data = {
    client_id     = jsondecode(data.local_file.client_secret.content).web.client_id
    client_secret = jsondecode(data.local_file.client_secret.content).web.client_secret
  }
}

data "kubectl_path_documents" "backend_config" {
  pattern = "./manifests/backend_config.yaml"
  vars = {
    backend_config_name = var.iap.backend_config_name
    secret_name         = var.iap.secret_name
  }
}
resource "kubectl_manifest" "backend_config" {
  depends_on = [
    google_container_cluster.primary,
  ]
  count     = length(data.kubectl_path_documents.backend_config.documents)
  yaml_body = element(data.kubectl_path_documents.backend_config.documents, count.index)
}
