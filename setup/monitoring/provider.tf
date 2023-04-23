terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = "1.31.1"
    }
  }
}

variable "GRAFANA_APIKEY" {
  type = string
  description = "Grafana internal API key (not cloud)."
}

locals {
  influxdb_url = "http://influxdb.influxdb:8086"
  loki_url = "http://loki.loki:3100"
  org_id = 1
}

provider "grafana" {
  url = "https://grafana.internal.com"
  auth = var.GRAFANA_APIKEY
  insecure_skip_verify = false
  org_id = local.org_id
}
