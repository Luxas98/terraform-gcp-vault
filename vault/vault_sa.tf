resource "random_string" "role_suffix" {
  length  = 8
  special = false
}

resource "google_service_account" "vault-sa" {
  project = "${var.project_id}"
  account_id   = "vault-server"
  display_name = "Vault Service Account"
}

resource "google_service_account_key" "vault-sa-key" {
  service_account_id = "${google_service_account.vault-sa.name}"
}

resource "google_project_iam_custom_role" "kube-api-ro" {
  // Randomize the name to avoid collisions with deleted roles
  // (Deleted roles prevent similarly named roles from being created for up to 30 days)
  // See https://cloud.google.com/iam/docs/creating-custom-roles#deleting_a_custom_role
  project = "${var.project_id}"
  role_id = "kube_api_ro_${random_string.role_suffix.result}"

  title       = "Kubernetes API (RO)"
  description = "Grants read-only API access that can be further restricted with RBAC"

  permissions = [
    "container.apiServices.get",
    "container.apiServices.list",
    "container.clusters.get",
    "container.clusters.getCredentials",
  ]
}

resource "google_project_iam_member" "kube-api-admin" {
  project = "${var.project_id}"
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.vault-sa.email}"
}

resource "google_project_iam_binding" "kube-api-ro" {
  project = "${var.project_id}"
  role = "projects/${var.project_id}/roles/${google_project_iam_custom_role.kube-api-ro.role_id}"

  members = [
    "serviceAccount:${google_service_account.vault-sa.email}",
  ]
}

resource "google_storage_bucket_iam_binding" "storage-object-admin-binding" {
  bucket = "${google_storage_bucket.vault-store.name}"
  role = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.vault-sa.email}"
  ]
  depends_on = [google_storage_bucket.vault-store, google_service_account.vault-sa]
}

resource "google_storage_bucket_iam_binding" "storage-object-ro-binding" {
  bucket = "${google_storage_bucket.vault-store.name}"
  role = "roles/storage.legacyBucketReader"
  members = [
    "serviceAccount:${google_service_account.vault-sa.email}"
  ]

  depends_on = [google_storage_bucket.vault-store, google_service_account.vault-sa]
}