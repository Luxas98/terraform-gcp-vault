provider "google-beta" {
  region = "${var.region}"
  project_id = "${var.project_id}"
}

provider "kubernetes" {
  alias = "primary"
  host = "${var.cluster_endpoint}"
  cluster_ca_certificate = "${var.cluster_ca}"
}

provider "kubernetes" {
  alias = "vault"
  cluster_ca_certificate = "${var.vault_cluster_cert}"
}

provider "vault" {
  address = "https://${var.vault_address}"
  token = "${var.vault_token}"
  ca_cert_file = "${var.vault_ca}"
}