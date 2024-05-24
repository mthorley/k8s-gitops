
# defined by TF_VAR_ENV environment variable
variable "ENV" {
   description = "Environment name, either prod or staging"
   type = string
#   default = "staging"
   validation {
      condition     = can(regex("^staging$|^prod$", var.ENV))
      error_message = "Allowed values for env are \"staging\" or \"prod\"."
   }
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
