resource "kubernetes_stateful_set" "vault" {

  provider = kubernetes.vault

  metadata {
    name = "vault"
    labels = {
      component = "vault"
    }
  }

  spec {
    service_name = "vault"
    replicas = 1

    selector {
      match_labels = {
        app  = "vault"
      }
    }

    template {
      metadata {
        labels = {
          app = "vault"
          component = "vault"
        }
        annotations = {}
      }

      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 60
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key = "app"
                    operator = "In"
                    values = ["vault"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        termination_grace_period_seconds = 10

        container {
          name = "vault-init"
          image = "registry.hub.docker.com/sethvargo/vault-init:1.0.0"
          image_pull_policy = "IfNotPresent"
          resources {
            requests {
              cpu = "100m"
              memory = "64Mi"
            }
          }
          env {
            name = "CHECK_INTERVAL"
            value = "5"
          }

          env {
            name = "VAULT_ADDR"
            value = "http://127.0.0.1:8200"
          }

          env {
            name = "VAULT_SECRET_SHARES"
            value = "1"
          }

          env {
            name = "VAULT_SECRET_THRESHOLD"
            value = "1"
          }

          env {
            name = "GCS_BUCKET_NAME"
            value_from {
              config_map_key_ref {
                name = "vault"
                key = "gcs_bucket_name"
              }
            }

          }

          env {
            name = "KMS_KEY_ID"
            value_from {
              config_map_key_ref {
                name = "vault"
                key = "kms_key_id"
              }
            }
          }
        }
        container {
          name = "vault"
          image = "registry.hub.docker.com/library/vault:1.2.2"
          image_pull_policy = "IfNotPresent"
          args = ["server"]
          security_context {
            capabilities {
              add = ["IPC_LOCK"]
            }
          }

          port {
            container_port = 8200
            name = "vault-port"
            protocol = "TCP"
          }

          port {
            container_port = 8201
            name = "cluster-port"
            protocol = "TCP"
          }

          resources {
            requests {
              cpu = "500m"
              memory = "256Mi"
            }
          }

          volume_mount {
            mount_path = "/etc/vault/tls"
            name = "vault-tls"
          }

          env {
            name = "GCS_BUCKET_NAME"
            value_from {
              config_map_key_ref {
                name = "vault"
                key = "gcs_bucket_name"
              }
            }
          }

          env {
            name = "KMS_PROJECT"
            value_from {
              config_map_key_ref {
                name = "vault"
                key = "kms_project"
              }
            }
          }

          env {
            name = "KMS_REGION"
            value_from {
              config_map_key_ref {
                name = "vault"
                key = "kms_region"
              }
            }
          }

          env {
            name = "KMS_KEY_RING"
            value_from {
              config_map_key_ref {
                name = "vault"
                key = "kms_key_ring"
              }
            }
          }

          env {
            name = "KMS_CRYPTO_KEY"
            value_from {
              config_map_key_ref {
                name = "vault"
                key = "kms_crypto_key"
              }
            }
          }

          env {
            name = "LOAD_BALANCER_ADDR"
            value_from {
              config_map_key_ref {
                name = "vault"
                key = "load_balancer_address"
              }
            }
          }

          env {
            name = "POD_IP_ADDR"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name = "VAULT_ADDR"
            value = "http://127.0.0.1:8200"
          }

          env {
            name = "VAULT_LOCAL_CONFIG"
            value = "api_addr = \"https://$(LOAD_BALANCER_ADDR)\"\ncluster_addr = \"https://$(POD_IP_ADDR):8201\"\nlog_level = \"debug\"\nui = false\nseal \"gcpckms\" {\n    project    = \"$(KMS_PROJECT)\"\n    region     = \"$(KMS_REGION)\"\n    key_ring   = \"$(KMS_KEY_RING)\"\n    crypto_key = \"$(KMS_CRYPTO_KEY)\"\n}\nstorage \"gcs\" {\n    bucket     = \"$(GCS_BUCKET_NAME)\"\n    ha_enabled = \"true\"\n}\nlistener \"tcp\" {\n    address     = \"127.0.0.1:8200\"\n    tls_disable = \"true\"\n}\nlistener \"tcp\" {\n    address       = \"$(POD_IP_ADDR):8200\"\n    tls_cert_file = \"/etc/vault/tls/vault.crt\"\n    tls_key_file  = \"/etc/vault/tls/vault.key\"\n    tls_disable_client_certs = true\n}"
          }

          readiness_probe {
            http_get {
              path = "/v1/sys/health?standbyok=true"
              port = "8200"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 5
            period_seconds = 5
          }
        }

        volume {
          name = "vault-tls"
          secret {
            secret_name = "vault-tls"
          }
        }
      }
    }
  }
}

resource "google_compute_address" "vault-ip" {
  name = "vault"
  project = "${var.project_id}"
  region = "${var.region}"

  depends_on = [google_project_service.compute-service]
}

resource "kubernetes_service" "vault" {
  provider = kubernetes.vault

  metadata {
    name = "vault"

    labels = {
      app = "vault"
      component = local.component_name
    }
  }
  spec {
    type = "LoadBalancer"
    load_balancer_ip = "${google_compute_address.vault-ip.address}"
    external_traffic_policy = "Local"

    selector = {
      app = "vault"
    }

    port {
      name = "vault-port"
      port = 443
      target_port = "8200"
    }

  }
}