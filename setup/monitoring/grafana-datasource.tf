resource "grafana_data_source" "influxdb_power" {
  type                = "influxdb"
  name                = "InfluxDB-power"
  uid                 = "gvJin5OVz"
  url                 = local.influxdb_url
  database_name       = "power" # FIXME: use local vars from influxdb
  json_data_encoded   = jsonencode({})
}

resource "grafana_data_source" "influxdb_rackcontroller" {
  type                = "influxdb"
  name                = "InfluxDB-rackcontroller"
  uid                 = "MmT8wId4z"
  url                 = local.influxdb_url
  database_name       = "rackcontroller" # FIXME: use local vars from influxdb
  json_data_encoded   = jsonencode({})
}

resource "grafana_data_source" "influxdb_tasmota" {
  type                = "influxdb"
  name                = "InfluxDB-Tasmota"
  uid                 = "ZxLMwSd4z"
  url                 = local.influxdb_url
  database_name       = "tasmota_rssi" # FIXME: use local vars from influxdb
  json_data_encoded   = jsonencode({})
}

resource "grafana_data_source" "influxdb_unifitemps" {
  type                = "influxdb"
  name                = "InfluxDB-unifitemps"
  uid                 = "MmT8wId4y"
  url                 = local.influxdb_url
  database_name       = "unifitemps" # FIXME: use local vars from influxdb
  json_data_encoded   = jsonencode({})
}

resource "grafana_data_source" "loki" {
  type                = "loki"
  name                = "Loki"
  uid                 = "2_DjQId4k"
  url                 = local.loki_url
  json_data_encoded   = jsonencode({})
}
