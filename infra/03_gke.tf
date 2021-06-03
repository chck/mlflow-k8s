variable "gke" {
  type = map(string)
  default = {
    cluster_name       = "mlflow-k8s"
    k8s_version        = "1.19.9-gke.1900"
    initial_node_count = 1
    min_node_count     = 1
    max_node_count     = 1
    machine_type       = "e2-medium"
    disk_size_gb       = 100
  }
}

resource "google_container_cluster" "primary" {
  provider = google-beta

  name               = var.gke.cluster_name
  location           = var.common.region
  min_master_version = var.gke.k8s_version

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = var.gke.initial_node_count

  vertical_pod_autoscaling {
    enabled = true
  }
  addons_config {
    horizontal_pod_autoscaling {
      disabled = true
    }
    http_load_balancing {
      disabled = false
    }
    cloudrun_config {
      disabled = false
    }
  }
  workload_identity_config {
    identity_namespace = "${var.common.project}.svc.id.goog"
  }
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

resource "google_container_node_pool" "preemptible_nodes" {
  provider = google-beta

  name               = "${var.gke.cluster_name}-preemptible-nodes"
  cluster            = google_container_cluster.primary.name
  location           = var.common.region
  node_locations     = [var.common.zone]
  initial_node_count = var.gke.initial_node_count

  node_config {
    preemptible  = true
    machine_type = var.gke.machine_type
    disk_size_gb = var.gke.disk_size_gb
    metadata = {
      disable-legacy-endpoints = "true"
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER" # Enable workload identity on the node
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = var.gke.min_node_count
    max_node_count = var.gke.max_node_count
  }
}

output "cluster_ca_certificate" {
  value = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}

output "gke_host_endpoint" {
  value = "https://${google_container_cluster.primary.endpoint}"
}
