
resource "grafana_dashboard" "power" {
  config_json = file("${path.module}/../../infrastructure/common/kube-prometheus-stack/dashboards/power.json")
}

resource "grafana_dashboard" "rackcontroller" {
  config_json = file("${path.module}/../../infrastructure/common/kube-prometheus-stack/dashboards/rack-controller-temperatures.json")
}

resource "grafana_dashboard" "tasmota" {
  config_json = file("${path.module}/../../infrastructure/common/kube-prometheus-stack/dashboards/tasmota.json")
}

resource "grafana_dashboard" "networklogs" {
  config_json = file("grafana-dashboardNetworklogs.json")
}

resource "grafana_dashboard" "cloudflare_tunnels" {
  config_json = file("${path.module}/../../infrastructure/common/kube-prometheus-stack/dashboards/cloudflare-tunnels.json")
}

resource "grafana_dashboard" "falco_events" {
  config_json = file("${path.module}/../../infrastructure/common/kube-prometheus-stack/dashboards/falco-events.json")
}
