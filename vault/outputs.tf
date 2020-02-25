output "bucket_id" {
  value = "${google_storage_bucket.vault-store.id}"
}

output "service_account_name" {
  value = "${google_service_account.vault-sa.email}"
}

output "vault_address" {
  value = "${google_compute_address.vault-ip.address}"
}

output "vault_ca" {
  value = "tls/${var.project_id}/ca.crt"
}

resource "null_resource" "vault_token" {
  provisioner "local-exec" {
    command = "sleep 10 && gsutil cat gs://${google_storage_bucket.vault-store.name}/root-token.enc | base64 --decode | gcloud kms decrypt --project ${var.project_id} --location ${var.region} --keyring ${google_kms_key_ring.vault-key-ring.name} --key ${google_kms_crypto_key.vault-init-key-ring.name} --ciphertext-file - --plaintext-file - > tls/${var.project_id}/root-token.enc"
  }

  triggers = {
    "after": "${kubernetes_stateful_set.vault.id}"
  }
}

data "local_file" "vault_token" {
  filename = "tls/${var.project_id}/root-token.enc"
  depends_on = [null_resource.vault_token, kubernetes_stateful_set.vault]
}

output "vault_token" {
  value = data.local_file.vault_token.content
  sensitive = true
  depends_on = [null_resource.vault_token, kubernetes_stateful_set.vault]
}

output "vault_cluster_cert" {
  value = base64decode(google_container_cluster.vault-cluster.master_auth[0].cluster_ca_certificate)
  sensitive = true
}