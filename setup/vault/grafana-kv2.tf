
# Grafana needs a grafana.ini file as a k8s secret which will contain sensitive data such as OAuth client ID/secrets etc.
# To manage this, the grafana.ini file is stored in vault but prepopulated with sensitive data via terraform templating.
# The secret is then rendered into the cluster via external-secrets-operator or other.

# -----------------------------------------------------------------------------
# grafana

resource "vault_policy" "grafana-secrets-policy" {
  name = "grafana-secrets-policy"

  policy = <<EOT
path "secret/data/grafana" {
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
  mount     = vault_mount.kvv2.path
  name      = "grafana"
  data_json = jsonencode(
    {
      "grafana.ini" = templatefile("${path.module}/grafana-ini-oauth.tftpl", {
         OAUTH_CLIENT_ID = var.AUTHENTIK_GRAFANA_CLIENTID,
         OAUTH_SECRET = var.AUTHENTIK_GRAFANA_SECRET,
         DOMAIN = "auth.internal.com",
         APP_SLUG = "grafana"
      })
    }
  )
}
