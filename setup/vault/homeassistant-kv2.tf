# Home Assistant (staging) holds no application secret in vault: its Pocket ID
# OIDC client is a public client with no secret, and everything else lives on
# the home-assistant-config PVC. The only thing needed here is the Cloudflare
# DNS token for the ACME DNS-01 challenge that issues homeassistant.${domain},
# which is why apps/common/homeassistant patches the generic
# external-secret-${APP} out of the secrets-eso-vault component.

resource "vault_policy" "homeassistant-secrets-policy" {
  name = "homeassistant-secrets-policy"

  policy = <<EOT
path "secret/data/homeassistant-cf-api-token" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "homeassistant" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "homeassistant-secrets-role"
  bound_service_account_names      = ["homeassistant"]
  bound_service_account_namespaces = ["homeassistant"]
  token_ttl                        = 86400
  token_policies                   = ["homeassistant-secrets-policy"]
}

# ACME DNS-01 token for the Home Assistant gateway cert, consumed by
# components/pki-certman-letsencrypt with APP=homeassistant.
resource "vault_kv_secret_v2" "homeassistant-cf-api-token" {
  mount = vault_mount.kvv2.path
  name  = "homeassistant-cf-api-token"
  data_json = jsonencode(
    {
      dns-api-token = var.CLOUDFLARE_DNS_API_TOKEN
    }
  )
}
