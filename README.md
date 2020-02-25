HashiCorp Vault deployment and management on Google Cloud Platform using terraform
========================================================================

Example of deployment, project registration and cluster registration to the hashicorp vault, based on: https://codelabs.developers.google.com/codelabs/vault-on-gke/index.html#0

## Vault

Description:

    Creates GKE cluster and deploys vault service

Folder: 

    vault
    
Script:

    ./deploy-vault.sh
    ./vault/login.sh 
    
Example:

    ./deploy-vault.sh my-project-id-1 organization-id.xy
    source ./vault/login.sh my-project-id-1
    
## Register project permissions into the vault

Description:

    This registers project credentials and permissions in vault so vault can dynamically create service accounts in the project.
    
Folder:

    vault-register-project-permissions
    
Script:

    ./add-project-to-vault.sh

Example:

    ./add-project-to-vault.sh my-project-id-1
    
## Register cluster to vault

Description:

    Allows cluster to login and use vault endpoints
    
Folder:

    vault-register-k8s-cluster
    
Script:

    ./add-project-to-vault.sh
    
Example:
    
    export CLUSTER_CA=<CLUSTER_CA_TO_BE_ADDED>
    ./add-project-to-vault.sh my-project-id-1 my-cluster https://XY.UVZ.ST.OPR
    
### Clean up

Google KMS keys and keyrings are not deleted immediately but rather marked as "DELETED" and set for clean up later on. This is causing resource already exists error when using terraform destroy and terraform apply again. Check `sciprts/fix_kms_keys.sh` how to update keys and import them if terraform state is destroyed but keys are still existing