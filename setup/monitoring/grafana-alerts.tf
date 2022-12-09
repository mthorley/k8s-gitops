data "grafana_folder" "folder" {
    title = "Default"
}

resource "grafana_rule_group" "security_rules" {
    name = "Security"
    interval_seconds = 10
    org_id = local.org_id
    folder_uid = data.grafana_folder.folder.uid

    rule {
        name = "alert_egress_not_network"
        annotations = {
            description: "Alert on any egress to the internet from trusted network of things"
            summary: "Egress Network Alert"
        }
        condition = "C"
        for = "0s"
        exec_err_state = "Alerting"
        no_data_state = "OK"
        labels = {
            security : "warning"
        }

        data {
            ref_id = "A"
            relative_time_range {
              from = 300
              to = 0
            }
            datasource_uid = grafana_data_source.loki.uid

            model = jsonencode({
                editorMode    = "code"
                // https://community.ui.com/questions/Analyzing-USG-firewall-logs-for-attack-visibility/91068a06-1627-4e3e-a673-410f51434528
                // `-D` represents dropped firewall logs 
                // `WAN_OUT` represents internet egress
                // $__interval is derived from relative_time_range above
                expr          = "rate(({job=\"ubnt-kern\"} |= `WAN_OUT` |= `-D`)[$__interval])"
                groupBy       = [
                    {
                        params = [
                            "$__interval",
                        ]
                        type   = "time"
                    },
                    {
                        params = [
                            "null",
                        ]
                        type   = "fill"
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
            query_type     = "range"
        }

        data {
            ref_id         = "B"
            datasource_uid = "-100"
            model          = jsonencode({
                conditions    = [
                    {
                        evaluator = {
                            params = []
                            type   = "gt"
                        }
                        operator  = {
                            type = "and"
                        }
                        query     = {
                            params = [
                                "B",
                            ]
                        }
                        reducer   = {
                            params = []
                            type   = "last"
                        }
                        type      = "query"
                    },
                ]
                datasource    = {
                    type = "__expr__"
                    uid  = "-100"
                }
                expression    = "A"
                hide          = false
                intervalMs    = 1000
                maxDataPoints = 43200
                reducer       = "last"
                refId         = "B"
                settings      = {
                    mode = ""
                }
                type          = "reduce"
            })
            relative_time_range {
                from = 3600
                to   = 0
            }
        }

        data {
            ref_id         = "C"
            datasource_uid = "-100"
            model          = jsonencode({
                conditions    = [
                        {
                            evaluator = {
                                params = [
                                    1,
                                ]
                                type   = "gt"
                            }
                            operator  = {
                                type = "and"
                            }
                            query     = {
                                params = [
                                    "C",
                                ]
                            }
                            reducer   = {
                                params = []
                                type   = "last"
                            }
                            type      = "query"
                        },
                    ]
                    datasource    = {
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
}