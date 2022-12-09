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
  url = "http://192.168.3.10/"
  auth = var.GRAFANA_APIKEY
  insecure_skip_verify = true
  org_id = local.org_id
}

resource "grafana_dashboard" "power" {
  config_json = file("grafana-dashboardPower.json")
}

resource "grafana_dashboard" "rackcontroller" {
  config_json = file("grafana-dashboardRackControllerTemperatures.json")
}

resource "grafana_dashboard" "tasmota" {
  config_json = file("grafana-dashboardTasmota.json")
}

resource "grafana_dashboard" "networklogs" {
  config_json = file("grafana-dashboardNetworklogs.json")
}
