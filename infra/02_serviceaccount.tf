resource "google_service_account" "sa" {
  account_id  = "mlflow-k8s"
  description = "for mlflow-k8s"
}

resource "google_service_account_iam_binding" "wi" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  members            = formatlist("serviceAccount:${local.common.project}.svc.id.goog[%s]", ["${var.deployment.k8s_namespace}/${var.deployment.ksa_name}"])
}

resource "google_project_iam_member" "sql" {
  project = local.common.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.sa.account_id}@${local.common.project}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "gcs_viewer" {
  project = local.common.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.sa.account_id}@${local.common.project}.iam.gserviceaccount.com"
}
