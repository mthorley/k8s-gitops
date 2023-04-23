
data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_scope_mapping" "default_scopes" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

// grafana
resource "authentik_provider_oauth2" "grafana-oidc-provider" {
  name               = "grafana-oidc-provider"
  client_id          = var.AUTHENTIK_GRAFANA_CLIENTID
  client_secret      = var.AUTHENTIK_GRAFANA_SECRET
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  redirect_uris = [ 
    "https://grafana.${var.INTERNAL_DOMAIN}/login/generic_oauth" 
  ]
  access_token_validity = "minutes=5"
  property_mappings     = data.authentik_scope_mapping.default_scopes.ids
  signing_key           = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "grafana" {
  name = "grafana"
  slug = "grafana"
  meta_icon         = "https://upload.wikimedia.org/wikipedia/commons/9/9d/Grafana_logo.png"
  protocol_provider = authentik_provider_oauth2.grafana-oidc-provider.id
}

/*/ nodered
resource "authentik_provider_oauth2" "nodered-oidc-provider" {
  name               = "nodered-oidc-provider"
  client_id          = var.AUTHENTIK_NODERED_CLIENTID
  client_secret      = var.AUTHENTIK_NODERED_SECRET
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  redirect_uris = [ 
    "https://nodred.${var.domain}/auth/strategy/callback/" 
  ]
  access_token_validity = "minutes=5"
  property_mappings     = data.authentik_scope_mapping.default_scopes.ids
  signing_key           = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "nodred" {
  name = "nodered"
  slug = "nodered"
  protocol_provider = authentik_provider_oauth2.nodered-oidc-provider.id
}
*/