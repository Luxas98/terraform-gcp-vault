terraform {
  # This module has been updated with 0.12 syntax, which means the example is no longer
  # compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

provider "google-beta" {
 region = "${var.region}"
 project = "${var.project_id}"
}

resource "google_project_iam_binding" "token-creator-iam" {
  project = "${var.project_id}"
  role = "roles/iam.serviceAccountTokenCreator"
  members = [
    "serviceAccount:${google_service_account.vault-sa.email}",
  ]
}

data "google_service_account_access_token" "vault-sa" {
  provider = "google-beta"
  target_service_account = google_service_account.vault-sa.email
  scopes = ["storage-ro", "cloud-platform"]

  depends_on = [google_service_account.vault-sa]
}

provider "kubernetes" {
  alias = "vault"
  host = "${google_container_cluster.vault-cluster.endpoint}"

  cluster_ca_certificate = base64decode(google_container_cluster.vault-cluster.master_auth[0].cluster_ca_certificate)
  token = "${data.google_service_account_access_token.vault-sa.access_token}"
}