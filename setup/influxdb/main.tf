terraform {
  required_providers {
    influxdb = {
      source = "DrFaust92/influxdb"
      version = "1.6.1"
    }
  }
}

variable "ENV" {}

// FIXME: FQDN this
provider "influxdb" {
  url = (var.ENV == "prod" ? format("%s", "http://192.168.2.20:8086") : format("%s", "http://192.168.3.20:8086"))
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

resource "influxdb_database" "airquality" {
  name = "airquality"
}

resource "influxdb_database" "isp" {
  name = "isp"
}
