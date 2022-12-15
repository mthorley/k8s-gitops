
variable "env" { 
   description = "Environment name, either prod or staging"
   type = string
   default = "staging"
   validation {
      condition     = can(regex("^staging$|^prod$", var.env))
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
