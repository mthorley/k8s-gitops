
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
