#!/usr/bin/env bash
# run as `source ./login.sh`
PROJECT_ID=${PROJECT_ID:=$1}
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials vault
export VAULT_ADDR=https://$(gcloud compute addresses describe vault --region europe-west4 --format 'value(address)')
cd ../clients
export VAULT_CACERT=$(pwd)"/tls/${PROJECT_ID}/ca.crt"
export VAULT_TOKEN="$(gsutil cat "gs://${PROJECT_ID}-vault-storage/root-token.enc" | \
  base64 --decode | \
  gcloud kms decrypt \
    --location europe-west4 \
    --keyring vault \
    --key vault-init \
    --ciphertext-file - \
    --plaintext-file -)"