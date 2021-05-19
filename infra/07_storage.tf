resource "google_storage_bucket" "artifact" {
  name          = "mlflow-k8s"
  location      = "ASIA"
  storage_class = "MULTI_REGIONAL"
}
