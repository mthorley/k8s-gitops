
# Grafana's own config (grafana.ini) lives in the kube-prometheus-stack
# HelmRelease, not here: the chart renders it into a ConfigMap, and mounting a
# vault-rendered file over /etc/grafana (as the pre-chart deployment did) would
# discard the provisioning paths the dashboard/datasource sidecars need.
#
# So vault holds only the values that have to stay out of that ConfigMap - the
# Pocket ID OIDC client - and external-secrets renders them into secret-grafana,
# which the chart injects as env vars.

# -----------------------------------------------------------------------------
# grafana

resource "vault_policy" "grafana-secrets-policy" {
  name = "grafana-secrets-policy"

  policy = <<EOT
path "secret/data/grafana" {
  capabilities = ["read", "list"]
}
path "secret/data/certs" {
  capabilities = ["read", "list"]
}
path "secret/data/grafana-cf-api-token" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "grafana" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "grafana-secrets-role"
  bound_service_account_names      = ["grafana"]
  bound_service_account_namespaces = ["monitoring"]
  token_ttl                        = 86400
  token_policies                   = ["grafana-secrets-policy"]
}

resource "vault_kv_secret_v2" "grafana" {
  mount = vault_mount.kvv2.path
  name  = "grafana"
  data_json = jsonencode(
    {
      # Pocket ID OIDC client for the Grafana login - read as
      # GF_AUTH_GENERIC_OAUTH_CLIENT_ID/_SECRET by the chart's envValueFrom in
      # infrastructure/common/monitoring-system/helmrelease.yaml.
      oidc-client-id     = var.POCKETID_GRAFANA_CLIENTID
      oidc-client-secret = var.POCKETID_GRAFANA_SECRET
    }
  )
}

/*resource "vault_kv_secret_v2" "certs" {
  mount     = vault_mount.kvv2.path
  name      = "certs"
  data_json = jsonencode(
    {
      intermediate-ca = vault_pki_secret_backend_intermediate_set_signed.intermediate.certificate
    }
  )
}*/

# ACME DNS-01 token for the monitoring ingresses (grafana/prometheus/alertmanager),
# consumed by components/pki-certman-letsencrypt with APP=grafana.
resource "vault_kv_secret_v2" "grafana-cf-api-token" {
  mount = vault_mount.kvv2.path
  name  = "grafana-cf-api-token"
  data_json = jsonencode(
    {
      dns-api-token = var.CLOUDFLARE_DNS_API_TOKEN
    }
  )
}
