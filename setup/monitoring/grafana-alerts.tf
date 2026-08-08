data "grafana_folder" "folder" {
  title = "Default"
}

resource "grafana_rule_group" "security_rules" {
  org_id           = local.org_id
  name             = "Security"
  interval_seconds = 10
  folder_uid       = data.grafana_folder.folder.uid

  rule {
    name = "alert_egress_not_network"
    annotations = {
      description : "Alert on any egress to the internet from trusted network of things"
      summary : "Egress Network Alert"
    }
    condition      = "C"
    for            = "0s"
    exec_err_state = "Alerting"
    no_data_state  = "OK"
    labels = {
      security : "warning"
    }

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = grafana_data_source.loki.uid

      model = jsonencode({
        editorMode = "code"
        // https://community.ui.com/questions/Analyzing-USG-firewall-logs-for-attack-visibility/91068a06-1627-4e3e-a673-410f51434528
        // `-D` represents dropped firewall logs 
        // `WAN_OUT` represents internet egress
        // $__interval is derived from relative_time_range above
        expr = "rate(({job=\"ubnt-kern\"} |= `WAN_OUT` |= `-D`)[$__interval])"
        groupBy = [
          {
            params = [
              "$__interval",
            ]
            type = "time"
          },
          {
            params = [
              "null",
            ]
            type = "fill"
          },
        ]
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        orderByTime   = "ASC"
        policy        = "default"
        queryType     = "range"
        refId         = "A"
        resultFormat  = "time_series"
        tags          = []
        }
      )
      query_type = "range"
    }

    data {
      ref_id         = "B"
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = []
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = [
                "B",
              ]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          },
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression    = "A"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        reducer       = "last"
        refId         = "B"
        settings = {
          mode = ""
        }
        type = "reduce"
      })
      relative_time_range {
        from = 3600
        to   = 0
      }
    }

    data {
      ref_id         = "C"
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [
                1,
              ]
              type = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = [
                "C",
              ]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          },
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression    = "B"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "threshold"
      })
      relative_time_range {
        from = 3600
        to   = 0
      }
    }
  }

  rule {
    name = "alert_falco_homeassistant"
    annotations = {
      description : "Alert on any Falco event tagged to the homeassistant namespace (CF-GRF-08) -- surfaces post-compromise activity Falco detects on the HA pod regardless of how access was gained"
      summary : "Falco event in homeassistant namespace"
      __dashboardUid__ : grafana_dashboard.falco_events.uid
      __panelId__ : "1"
    }
    condition      = "C"
    for            = "0s"
    exec_err_state = "Alerting"
    no_data_state  = "OK"
    labels = {
      security : "warning"
    }

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = grafana_data_source.loki.uid

      model = jsonencode({
        editorMode = "code"
        // Falco itself runs in the `falco` namespace regardless of which
        // namespace an event is about, so this can't filter on the Loki
        // `namespace` label -- it matches the JSON `k8s.ns.name` output
        // field instead (requires falco.yaml json_output: true, CF-FAL-02).
        expr = "count_over_time(({namespace=\"falco\"} |= `\"k8s.ns.name\":\"homeassistant\"`)[$__interval])"
        groupBy = [
          {
            params = [
              "$__interval",
            ]
            type = "time"
          },
          {
            params = [
              "null",
            ]
            type = "fill"
          },
        ]
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        orderByTime   = "ASC"
        policy        = "default"
        queryType     = "range"
        refId         = "A"
        resultFormat  = "time_series"
        tags          = []
        }
      )
      query_type = "range"
    }

    data {
      ref_id         = "B"
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = []
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = [
                "B",
              ]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          },
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression    = "A"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        reducer       = "last"
        refId         = "B"
        settings = {
          mode = ""
        }
        type = "reduce"
      })
      relative_time_range {
        from = 3600
        to   = 0
      }
    }

    data {
      ref_id         = "C"
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [
                0,
              ]
              type = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = [
                "C",
              ]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          },
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression    = "B"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "threshold"
      })
      relative_time_range {
        from = 3600
        to   = 0
      }
    }
  }

  rule {
    name = "alert_cloudflared_concurrent_requests_anomaly"
    annotations = {
      description : "Alert when cloudflared's concurrent-request count sustains well above what's plausible for a household with at most 3 simultaneous users (CF-GRF-02) -- catches scanning, credential-stuffing bursts, or a runaway retry loop, none of which a normal page load would produce"
      summary : "Anomalous concurrent request volume through the Cloudflare tunnel"
      __dashboardUid__ : grafana_dashboard.cloudflare_tunnels.uid
      __panelId__ : "4" # "Concurrent Requests" panel, see setup/monitoring/grafana-dashboardCloudflareTunnels.json
    }
    condition      = "C"
    for            = "2m"
    exec_err_state = "Alerting"
    no_data_state  = "OK"
    labels = {
      security : "warning"
    }

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      # Prometheus datasource UID as used by the existing cloudflared panels
      // in grafana-dashboardCloudflareTunnels.json. Not Terraform-managed
      // here (auto-provisioned by kube-prometheus-stack) -- re-check this
      // UID against the live instance if it's ever regenerated.
      datasource_uid = "P1809F7CD0C75ACF3"

      model = jsonencode({
        editorMode = "code"
        // Sum across both cloudflared replicas -- total concurrent requests
        // in flight through the tunnel right now, cluster-wide.
        expr          = "sum(cloudflared_tunnel_concurrent_requests_per_tunnel)"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        queryType     = "range"
        refId         = "A"
        }
      )
      query_type = "range"
    }

    data {
      ref_id         = "B"
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = []
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = [
                "B",
              ]
            }
            reducer = {
              params = []
              type   = "mean"
            }
            type = "query"
          },
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression    = "A"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        reducer       = "mean"
        refId         = "B"
        settings = {
          mode = ""
        }
        type = "reduce"
      })
      relative_time_range {
        from = 300
        to   = 0
      }
    }

    data {
      ref_id         = "C"
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              // 3 real users, generously assumed up to ~5 simultaneous
              // in-flight requests each during active use (page load,
              // multiple icons/assets, history-graph fetches) = ~15.
              // Sustaining a *mean* above that for a full 2 minutes (the
              // `for` above) is well beyond what active browsing produces
              // -- a normal brief page-load burst washes out of a 5-minute
              // mean. Tune this against the real baseline once it's live;
              // see CF-GRF-02 in setup/cf/CF Threat Model.md.
              params = [
                15,
              ]
              type = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = [
                "C",
              ]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          },
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression    = "B"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "threshold"
      })
      relative_time_range {
        from = 300
        to   = 0
      }
    }
  }

  rule {
    name = "alert_cloudflared_error_response_spike"
    annotations = {
      description : "Alert on a burst of 4xx/5xx responses from cloudflared (CF-GRF-01) -- covers auth failures (401), forbidden (403), not-found/scanning (404), and origin errors (5xx) in one rule. Deliberately excludes 2xx and 3xx: 304 Not Modified alone would fire constantly from normal browser asset caching, and that's not a signal of anything wrong"
      summary : "Spike in error responses through the Cloudflare tunnel"
      __dashboardUid__ : grafana_dashboard.cloudflare_tunnels.uid
      __panelId__ : "3" # "Response By Code" panel, see setup/monitoring/grafana-dashboardCloudflareTunnels.json
    }
    condition      = "C"
    for            = "0s"
    exec_err_state = "Alerting"
    no_data_state  = "OK"
    labels = {
      security : "warning"
    }

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = "P1809F7CD0C75ACF3" # Prometheus, see the concurrent-requests rule above

      model = jsonencode({
        editorMode = "code"
        // Sum of all 4xx/5xx responses across both cloudflared replicas in
        // the trailing 5 minutes -- any status code in that range, not just
        // 401/403/404, so an origin (HA) throwing 5xx also trips this.
        expr          = "sum(increase(cloudflared_tunnel_response_by_code{status_code=~\"4..|5..\"}[5m]))"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        queryType     = "range"
        refId         = "A"
        }
      )
      query_type = "range"
    }

    data {
      ref_id         = "B"
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = []
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = [
                "B",
              ]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          },
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression    = "A"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        reducer       = "last"
        refId         = "B"
        settings = {
          mode = ""
        }
        type = "reduce"
      })
      relative_time_range {
        from = 300
        to   = 0
      }
    }

    data {
      ref_id         = "C"
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              // 3 users occasionally fat-fingering a password or hitting a
              // stale bookmark might produce a handful of 4xx in 5 minutes
              // -- comfortably under 10. A scan, credential-stuffing burst,
              // or a flapping origin blows past that quickly. Tune against
              // the real baseline once live; see CF-GRF-01 in
              // setup/cf/CF Threat Model.md.
              params = [
                10,
              ]
              type = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = [
                "C",
              ]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          },
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression    = "B"
        hide          = false
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "threshold"
      })
      relative_time_range {
        from = 300
        to   = 0
      }
    }
  }
}