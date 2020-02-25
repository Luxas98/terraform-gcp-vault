resource "kubernetes_service_account" "vault-auth" {
  provider = kubernetes.primary
  metadata {
    name = "vault-auth"
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "role-vault-tokenreview-binding" {
  provider = kubernetes.primary
  metadata {
    name = "role-vault-tokenreview-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "system:auth-delegator"
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.vault-auth.metadata.0.name
  }
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "${var.cluster_name}-kube-cluster"
}

data "kubernetes_secret" "vault-secret" {
  provider = "kubernetes.primary"
  metadata {
    name = kubernetes_service_account.vault-auth.default_secret_name
  }

  depends_on = [kubernetes_service_account.vault-auth]
}

resource "vault_kubernetes_auth_backend_role" "gcp-reader" {
  backend                = vault_auth_backend.kubernetes.path
  bound_service_account_names = ["vault-auth"]
  bound_service_account_namespaces = ["*"]
  token_policies = ["${var.project_id}-ro"]
  role_name = "gcp-reader"
}

resource "vault_kubernetes_auth_backend_config" "primary-cluster-vault-auth" {
  backend            = "${vault_auth_backend.kubernetes.path}"
  kubernetes_host    = "https://${var.cluster_endpoint}"
  kubernetes_ca_cert = data.kubernetes_secret.vault-secret.data["ca.crt"]
  token_reviewer_jwt = data.kubernetes_secret.vault-secret.data["token"]
}