
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.25.2"
    }
    vault = {
      source = "hashicorp/vault"
      version = "4.7.0"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "vault" {
  # This will default to using $VAULT_ADDR unless set
  address = (local.env == "prod" ? var.vault_address_prod : var.vault_address_staging)
  token = (local.env == "prod" ? var.VAULT_ROOT_TOKEN_PROD : var.VAULT_ROOT_TOKEN_STG)
}

provider "kubernetes" {
  config_path = (local.env == "prod" ? "~/.kube/prod.config" : "~/.kube/c1.config")
}

