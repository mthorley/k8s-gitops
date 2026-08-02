terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = "4.43.0"
    }
  }
}

variable "GRAFANA_APIKEY" {
  type = string
  description = "Grafana internal API key (not cloud)."
}

variable "GRAFANA_URL" {
  type = string
  description = "Grafana base URL, e.g. https://grafana.<domain>"
}

locals {
  influxdb_url = "http://influxdb.influxdb:8086"
  loki_url = "http://loki.loki:3100"
  org_id = 1
}

provider "grafana" {
  url = var.GRAFANA_URL
  auth = var.GRAFANA_APIKEY
  insecure_skip_verify = true
  org_id = local.org_id
}
