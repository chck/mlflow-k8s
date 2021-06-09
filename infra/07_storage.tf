resource "google_storage_bucket" "artifact" {
  name          = "_YOUR_MLFLOW_BUCKET"
  location      = "ASIA"
  storage_class = "MULTI_REGIONAL"
}
