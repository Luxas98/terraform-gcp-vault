resource "google_kms_key_ring" "vault-key-ring" {
  name     = "vault"
  location = "${var.region}"
  project = "${var.project_id}"
  depends_on = [google_project_service.cloudkms-service]
}

resource "google_kms_crypto_key" "vault-init-key-ring" {
  name     = "vault-init"
  key_ring = "${google_kms_key_ring.vault-key-ring.self_link}"
  purpose = "ENCRYPT_DECRYPT"
  depends_on = [google_project_service.cloudkms-service]

  labels = {
    component = local.component_name
  }
}

resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  crypto_key_id = "${var.project_id}/${google_kms_key_ring.vault-key-ring.location}/${google_kms_key_ring.vault-key-ring.name}/${google_kms_crypto_key.vault-init-key-ring.name}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${google_service_account.vault-sa.email}",
  ]

  depends_on = [google_project_service.cloudkms-service]
}