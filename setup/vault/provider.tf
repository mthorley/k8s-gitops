
provider "vault" {
  # This will default to using $VAULT_ADDR unless set
  address = (var.env == "prod" ? var.vault_address_prod : var.vault_address_staging)
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
