#!/usr/bin/env bash

PROJECT_ID=${PROJECT_ID:=$1}
REGION=${REGION:=europe-west}
ZONE=${ZONE:=a}
ORGANIZATION_ID=${ORGANIZATION:=my-organization}

cd vault
terraform init
terraform apply -var="org_id=${ORGANIZATION_ID}" -var="project_id=${PROJECT_ID}" -var="region=${REGION}" -var="zone=${ZONE}"
cd -