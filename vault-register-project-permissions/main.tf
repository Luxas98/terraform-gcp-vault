provider "google-beta" {
  alias = "target"
  region = "${var.region}"
  project = "${var.project_id}"
}

provider "vault" {
  address = "https://${var.vault_address}"
  token = "${var.vault_token}"
  ca_cert_file = "${var.vault_ca}"
}

resource "google_service_account" "vault-sa-creator" {
  project = "${var.project_id}"
  account_id   = "vault-sa-creator"
  display_name = "Vault SA for vault secret engine to access gcp and create new service accounts"
}

resource "google_service_account_key" "vault-sa-creator-key" {
  service_account_id = "${google_service_account.vault-sa-creator.name}"
}

resource "google_project_iam_custom_role" "resource-iam-manager" {
  provider = "google-beta.target"
  role_id     = "vaultProjectPolicyAdmin"
  title       = "vaultProjectPolicyAdmin"
  description = "Role for Vault secret backend codelab to manage project IAM policy"
  permissions = ["resourcemanager.projects.getIamPolicy", "resourcemanager.projects.setIamPolicy"]
}

resource "google_project_iam_binding" "iam-policy-admin" {
  project = "${var.project_id}"
  role    = "projects/${var.project_id}/roles/${google_project_iam_custom_role.resource-iam-manager.role_id}"

  members = [
    "serviceAccount:${google_service_account.vault-sa-creator.email}",
  ]
}

resource "google_project_iam_binding" "iam-key-admin" {
  project = "${var.project_id}"
  role    = "roles/iam.serviceAccountKeyAdmin"

  members = [
    "serviceAccount:${google_service_account.vault-sa-creator.email}",
  ]
}

resource "google_project_iam_binding" "iam-account-admin" {
  project = "${var.project_id}"
  role    = "roles/iam.serviceAccountAdmin"

  members = [
    "serviceAccount:${google_service_account.vault-sa-creator.email}",
  ]
}

resource "vault_gcp_secret_backend" "gcp" {
  credentials = "${base64decode(google_service_account_key.vault-sa-creator-key.private_key)}"
  path = "${var.project_id}"
  max_lease_ttl_seconds = 3600  # 60 minutes
  default_lease_ttl_seconds = 3400 # < 60 minutes days
}

output "vault_backend_path" {
  value = vault_gcp_secret_backend.gcp.path
}

output "vault_sa_creator_keys" {
  value = "${base64decode(google_service_account_key.vault-sa-creator-key.private_key)}"
}

resource "vault_policy" "project-ro" {
  provider = "vault"
  name = "${var.project_id}-ro"
  policy = <<EOH
path "${var.project_id}/*" {
  capabilities = ["read", "list"]
}
EOH
}