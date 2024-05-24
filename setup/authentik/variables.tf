variable "AUTHENTIK_GRAFANA_CLIENTID" {
  type = string
  description = "Grafana client id for OAuth"
}

variable "AUTHENTIK_GRAFANA_SECRET" {
  type = string
  description = "Grafana client secret for OAuth"
}

variable "INTERNAL_DOMAIN" {
  type = string
  description = "domain e.g. example.com"
}

variable "INTERNAL_DOMAIN_PROD" {
  type = string
  description = "domain e.g. example.com"
}

variable "EMAIL" {
    type = string
    description = "default user email"
}