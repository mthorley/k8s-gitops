terraform {
  required_providers {
    influxdb = {
      source = "DrFaust92/influxdb"
      version = "1.6.1"
    }
  }
}

// FIXME: FQDN this
provider "influxdb" {
  url      = "http://192.168.3.20:8086"
}

resource "influxdb_database" "rackcontroller" {
  name = "rackcontroller"
}

resource "influxdb_database" "tasmota" {
  name = "tasmota"
}

resource "influxdb_database" "unifitemps" {
  name = "unifitemps"
}

resource "influxdb_database" "power" {
  name = "power"
}
