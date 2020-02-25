resource "google_container_cluster" "vault-cluster" {
  provider = "google-beta"
  name     = "vault"
  location = "${var.region}-${var.zone}"
  project = "${var.project_id}"


  initial_node_count = 1

  logging_service = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  resource_labels = {
    component = local.component_name
  }

  node_config {
    machine_type = "n1-standard-2"
    service_account = "${google_service_account.vault-sa.email}"
    preemptible  = true

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/iam",
      "https://www.googleapis.com/auth/devstorage.full_control",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      service = "vault"
      component = local.component_name
    }

    tags = ["vault"]
  }

  # This enables IP-aliasing
  ip_allocation_policy {}

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    # Enable network policy configurations (like Calico).
    network_policy_config {
      disabled = false
    }
  }

}