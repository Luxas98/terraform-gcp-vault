resource "google_storage_bucket" "vault-store" {
  name = "${var.project_id}-vault-storage"
  location = "${var.region}"
  project = "${var.project_id}"
  force_destroy = true
  storage_class = "REGIONAL"

  labels = {
    component = local.component_name
  }
}

resource "google_storage_bucket_acl" "vault-store-acl" {
  bucket = "${google_storage_bucket.vault-store.name}"
  role_entity = [
    "OWNER:user-${google_service_account.vault-sa.email}"
  ]

  depends_on = [google_storage_bucket.vault-store, google_service_account.vault-sa]
}