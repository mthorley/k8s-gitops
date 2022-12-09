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
