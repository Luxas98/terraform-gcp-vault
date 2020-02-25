#!/usr/bin/env bash
PROJECT_ID=${PROJECT_ID:=$1}
CLUSTER_NAME=${CLUSTER_NAME:=$2}
CLUSTER_ENDPOINT=${CLUSTER_ENDPOINT:=$3}

CLUSTER_CA=${CLUSTER_CA:=""}
REGION=${REGION:="europe-west4"}

cd vault
terraform init
VAULT_ADDRESS=$(terraform output vault_address)
VAULT_CA=$(terraform output vault_ca)
VAULT_CLUSTER_CERT=$(terraform output vault_cluster_cert)
VAULT_TOKEN=$(terraform output vault_token)
cd -

cd vault-register-k8s-cluster
terraform init
terraform workspace select ${CLUSTER_NAME} || terraform workspace new ${CLUSTER_NAME}
terraform apply -var="vault_address=${VAULT_ADDRESS}" -var="vault_token=${VAULT_TOKEN}" -var="vault_ca=${VAULT_CA}" -var="vault_cluster_cert=${VAULT_CLUSTER_CERT}" -var="region=${REGION}" -var="cluster_endpoint=${CLUSTER_ENDPOINT}" -var="cluster_name=${CLUSTER_NAME}" -var="cluster_ca=${CLUSTER_CA}" -var="project_id=${PROJECT_ID}"
cd -