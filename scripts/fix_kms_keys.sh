#!/usr/bin/env bash
set -e

CLIENT_NAME=${CLIENT_NAME:=$1}
TF_VAR_org_id=${TF_VAR_org_id:=<ORGANIZATION-ID}
TF_VAR_billing_account=${TF_VAR_billing_account:=<MY-BILLING-ACCOUNT>}
TF_ADMIN=${TF_ADMIN:=ci-cd-241510}
TF_CREDS=path/to/terraform-admin.json
REGION=europe-west4
ZONE=a

terraform init
terraform workspace select ${CLIENT_NAME}
PROJECT_ID=$(terraform output project_id)

gcloud kms keys versions restore 1 --location europe-west4 --keyring vault --key vault-init --project $PROJECT_ID || true
gcloud kms keys versions enable 1 --location europe-west4 --keyring vault --key vault-init --project $PROJECT_ID || true

terraform import -var "client_name=${CLIENT_NAME}" -var "admin_project_id=${TF_ADMIN}" -var "org_id=${TF_VAR_org_id}" -var "billing_account=${TF_VAR_billing_account}" -var "region=${REGION}" -var "zone=${ZONE}" -var "credentials=${TF_CREDS}" google_kms_crypto_key.vault-init-key-ring projects/${PROJECT_ID}/locations/europe-west4/keyRings/vault/cryptoKeys/vault-init
terraform import -var="client_name=${CLIENT_NAME}" -var="admin_project_id=${TF_ADMIN}" -var="org_id=${TF_VAR_org_id}" -var="billing_account=${TF_VAR_billing_account}" -var="region=${REGION}" -var="zone=${ZONE}" -var="credentials=${TF_CREDS}" google_kms_key_ring.vault-key-ring projects/${PROJECT_ID}/locations/europe-west4/keyRings/vault