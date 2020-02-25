#!/usr/bin/env bash
PROJECT_ID=${PROJECT_ID:=$1}
REGION=${REGION:="europe-west4"}

cd vault
terraform init
VAULT_ADDRESS=$(terraform output vault_address)
VAULT_CA=$(terraform output vault_ca)
VAULT_CLUSTER_CERT=$(terraform output vault_cluster_cert)
VAULT_TOKEN=$(terraform output vault_token)
cd -

cd vault-register-project-permissions
terraform init
terraform workspace select ${PROJECT_ID} || terraform workspace new ${PROJECT_ID}
terraform apply -var="project_id=${PROJECT_ID}" -var="vault_address=${VAULT_ADDRESS}" -var="vault_token=${VAULT_TOKEN}" -var="vault_ca=${VAULT_CA}" -var="region=${REGION}"
cd -