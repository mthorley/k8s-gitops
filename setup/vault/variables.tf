
# The environment is the workspace, not a variable. A separate ENV variable let
# the selected state and the targeted cluster disagree - applying the staging
# workspace with ENV=prod rewrote production Vault from staging state, and a
# kubeconfig pointing at the wrong cluster wrote staging's CA into prod's
# Kubernetes auth. Deriving everything from terraform.workspace makes the Vault
# address, token, kubeconfig and domains always match the state being written.
#
# Indexing the map fails the plan in any other workspace (including "default"),
# which is the point - there is no safe fallback.
locals {
  env = {
    prod    = "prod"
    staging = "staging"
  }[terraform.workspace]
}

# prod variables
variable "master_host_port_prod" {
   default = "https://192.168.2.101:6443"
}

variable "vault_address_prod" {
   default = "http://192.168.2.28:8200"
}

# staging variables
variable "master_host_port_staging" {
   default = "https://192.168.3.101:6443"
}

variable "vault_address_staging" {
   default = "http://192.168.3.28:8200"
}

variable "INTERNAL_DOMAIN" {
  type = string
  description = "domain e.g. example.com"
}

variable "INTERNAL_DOMAIN_PROD" {
  type = string
  description = "domain e.g. example.com"
}

variable "VAULT_ROOT_TOKEN_STG" {
  type = string
  description = "vault staging token"
}

variable "VAULT_ROOT_TOKEN_PROD" {
  type = string
  description = "vault prod token"
}
