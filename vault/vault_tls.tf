resource "kubernetes_config_map" "vault" {
  provider = kubernetes.vault

  metadata {
    name = "vault"
  }

  data = {
    load_balancer_address = "${google_compute_address.vault-ip.address}"
    gcs_bucket_name = "${google_storage_bucket.vault-store.name}"
    kms_project = "${var.project_id}"
    kms_region = "${var.region}"
    kms_key_ring = "${google_kms_key_ring.vault-key-ring.name}"
    kms_crypto_key = "${google_kms_crypto_key.vault-init-key-ring.name}"
    kms_key_id = "projects/${var.project_id}/locations/${var.region}/keyRings/${google_kms_key_ring.vault-key-ring.name}/cryptoKeys/${google_kms_crypto_key.vault-init-key-ring.name}"
  }
}

data "local_file" "vault-combined" {
  filename = "tls/${var.project_id}/vault-combined.crt"

  depends_on = [null_resource.combine-certs]
}

data "local_file" "vault-key" {
  filename = "tls/${var.project_id}/vault.key"
  depends_on = [null_resource.sign-vault-key]
}

data "local_file" "ca-crt" {
  filename = "tls/${var.project_id}/ca.crt"
  depends_on = [null_resource.sign-ca-key]
}

resource "kubernetes_secret" "vault-tls" {
  provider = kubernetes.vault
  metadata {
    name = "vault-tls"
  }

  data = {
    "vault.crt" = data.local_file.vault-combined.content
    "vault.key" = data.local_file.vault-key.content
    "ca.crt" = data.local_file.ca-crt.content
  }

  depends_on = [null_resource.combine-certs, null_resource.sign-vault-key, null_resource.sign-ca-key]
}