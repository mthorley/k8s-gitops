terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = "1.31.1"
    }
  }
}

provider "grafana" {
  url = "http://192.168.3.10/"
  auth = "eyJrIjoiQVVSNFc1YUZvNFNIRnZFWHBac21pSTFCRFF5VlN0aVUiLCJuIjoidGVycmFmb3JtIiwiaWQiOjF9"
  insecure_skip_verify = true
  org_id = 1
}

locals {
  influxdb_url = "http://influxdb.influxdb:8086"
  loki_url = "http://loki.loki:3100"
}

resource "grafana_data_source" "influxdb_power" {
  type                = "influxdb"
  name                = "InfluxDB-power"
  url                 = local.influxdb_url
  database_name       = "power" # FIXME: use local vars from influxdb
  json_data_encoded   = jsonencode({})
}

resource "grafana_data_source" "influxdb_rackcontroller" {
  type                = "influxdb"
  name                = "InfluxDB-rackcontroller"
  url                 = local.influxdb_url
  database_name       = "rackcontroller" # FIXME: use local vars from influxdb
  json_data_encoded   = jsonencode({})
}

resource "grafana_data_source" "influxdb_tasmota" {
  type                = "influxdb"
  name                = "InfluxDB-Tasmota"
  url                 = local.influxdb_url
  database_name       = "tasmota_rssi" # FIXME: use local vars from influxdb
  json_data_encoded   = jsonencode({})
}

resource "grafana_data_source" "influxdb_unifitemps" {
  type                = "influxdb"
  name                = "InfluxDB-unifitemps"
  url                 = local.influxdb_url
  database_name       = "unifitemps" # FIXME: use local vars from influxdb
  json_data_encoded   = jsonencode({})
}

resource "grafana_data_source" "loki" {
  type                = "loki"
  name                = "Loki"
  url                 = local.loki_url
  json_data_encoded   = jsonencode({})
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
