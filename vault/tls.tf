resource "null_resource" "create-tls-directory" {
  provisioner "local-exec" {
    command = "mkdir -p tls/${var.project_id}"
  }
}

resource "local_file" "create-openssl-config" {
  content = <<EOF
[req]
default_bits = 2048
encrypt_key  = no
default_md   = sha256
prompt       = no
utf8         = yes

distinguished_name = req_distinguished_name
req_extensions     = v3_req

[req_distinguished_name]
C  = NL
ST = Nord Holland
L  = Cloud
O  = ${var.org_id}
CN = vault

[v3_req]
basicConstraints     = CA:FALSE
subjectKeyIdentifier = hash
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth, serverAuth
subjectAltName       = @alt_names

[alt_names]
IP.1  = ${google_compute_address.vault-ip.address}
DNS.1 = vault.default.svc.cluster.local
EOF
  filename = "tls/${var.project_id}/openssl.cnf"

  depends_on = [null_resource.create-tls-directory]
}

resource "null_resource" "generate-vault-key" {
  provisioner "local-exec" {
    command = "openssl genrsa -out tls/${var.project_id}/vault.key 2048"
  }

  triggers = {
    "before": "${local_file.create-openssl-config.id}"
  }

  depends_on = [null_resource.create-tls-directory]
}

resource "null_resource" "sign-vault-key" {
  provisioner "local-exec" {
    command = "openssl req -new -key \"tls/${var.project_id}/vault.key\" -out \"tls/${var.project_id}/vault.csr\" -config \"tls/${var.project_id}/openssl.cnf\""
  }

  depends_on = [null_resource.generate-vault-key, local_file.create-openssl-config, null_resource.create-tls-directory]
}

resource "null_resource" "generate-ca-key" {
  provisioner "local-exec" {
    command = "openssl req -new -newkey rsa:2048 -days 1200 -nodes -x509 -subj \"/C=NL/ST=Nord Holland/L=Cloud/O=${var.org_id} CA\" -keyout \"tls/${var.project_id}/ca.key\" -out \"tls/${var.project_id}/ca.crt\""
  }

  triggers = {
    "before": "${local_file.create-openssl-config.id}"
  }

  depends_on = [null_resource.create-tls-directory]
}

resource "null_resource" "sign-ca-key" {
  provisioner "local-exec" {
    command = "openssl x509 -req -days 1200 -in \"tls/${var.project_id}/vault.csr\" -CA \"tls/${var.project_id}/ca.crt\" -CAkey \"tls/${var.project_id}/ca.key\" -CAcreateserial -extensions v3_req -extfile \"tls/${var.project_id}/openssl.cnf\" -out \"tls/${var.project_id}/vault.crt\""
  }

  depends_on = [null_resource.generate-ca-key, null_resource.create-tls-directory]
}

resource "null_resource" "combine-certs" {
  provisioner "local-exec" {
    command = "cat \"tls/${var.project_id}/vault.crt\" \"tls/${var.project_id}/ca.crt\" > \"tls/${var.project_id}/vault-combined.crt\""
  }

  depends_on = [null_resource.sign-ca-key, null_resource.create-tls-directory]
}