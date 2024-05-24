
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.25.2"
    }
    vault = {
      source = "hashicorp/vault"
      version = "3.24.0"
    }
  }
}

provider "vault" {
  # This will default to using $VAULT_ADDR unless set
  address = (var.ENV == "prod" ? var.vault_address_prod : var.vault_address_staging)
  token = (var.ENV == "prod" ? var.VAULT_ROOT_TOKEN_PROD : var.VAULT_ROOT_TOKEN_STG)
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
