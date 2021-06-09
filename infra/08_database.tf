variable "database" {
  type = map(string)
  default = {
    # NOTE: Be careful the error that you cannot reuse the name of the deleted instance until one week from the deletion date.
    instance_name = "mlflow-k8s"
    host          = "127.0.0.1:5432"
    user_name     = "postgres"
    secret_name   = "mlflow-secret"
  }
}

resource "google_sql_database_instance" "postgres" {
  name             = var.database.instance_name
  database_version = "POSTGRES_13"
  region           = local.common.region
  # NOTE: `deletion_protection` is recommended to not set this field (or set it to true) until you're ready to destroy the instance and its databases.
  deletion_protection = false
  settings {
    # https://cloud.google.com/sql/docs/postgres/create-instance#machine-types
    tier = "db-custom-4-15360"
    backup_configuration {
      enabled    = true
      start_time = "22:00"
    }
  }
}

resource "random_password" "db_password" {
  length = 16
}

resource "google_sql_user" "postgres" {
  depends_on = [
    google_sql_database_instance.postgres,
  ]
  name     = var.database.user_name
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}

provider "postgresql" {
  scheme   = "gcppostgres"
  host     = google_sql_database_instance.postgres.connection_name
  username = google_sql_user.postgres.name
  password = google_sql_user.postgres.password
}
resource "postgresql_database" "mlflow" {
  depends_on = [
    google_sql_database_instance.postgres,
  ]
  for_each = local.users
  name     = "u_${each.value}"
}

resource "kubernetes_secret" "mlflow_secret" {
  metadata {
    name = var.database.secret_name
  }
  data = {
    DB_HOST = var.database.host
    DB_USER = google_sql_user.postgres.name
    DB_PASS = google_sql_user.postgres.password
  }
}
