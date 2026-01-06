
variable "HUE_TOKEN" {
  type = string
  description = "Hue internal token"
}

variable "SONOS_DININGROOM_R" {
  type = string
  description = "Sonos mac"
}

variable "SONOS_DININGROOM_L" {
  type = string
  description = "Sonos mac"
}

variable "SONOS_WHISKYROOM_L" {
  type = string
  description = "Sonos mac"
}

variable "SONOS_WHISKYROOM_R" {
  type = string
  description = "Sonos mac"
}

variable "ZEN_WIFI_USER" {
  type = string
  description = "Zen thermostat"
}

variable "ZEN_WIFI_PASSWORD" {
  type = string
  description = "Zen thermostat"
}

variable "UNIFI_USER" {
  type = string
  description = "unifi admin"
}

variable "UNIFI_PASSWORD" {
  type = string
  description = "unifi admin password"
}

variable "MONGODB_INIT_DB_USER" {
  type = string
  description = "mongo admin"
}

variable "MONGODB_INIT_DB_PASSWORD" {
  type = string
  description = "mongo admin password"
}

variable "COINSPOT_SECRET_RO" {
  type = string
}

variable "COINSPOT_KEY_RO" {
  type = string
}

variable "TELEGRAM_BOT_NAME" {
  type = string
}

variable "TELEGRAM_BOT_TOKEN" {
  type = string
}

variable "TELEGRAM_CHAT_ID" {
  type = string
}

variable "AUTH_SHARED_SECRET" {
  type = string
  description = "Freeradius authentication secret"
}

variable "NODERED_MQTT_USER" {
  type = string
}

variable "NODERED_MQTT_PASSWORD" {
  type = string
}

variable "TASMOTA_MQTT_USER" {
  type = string
}

variable "TASMOTA_MQTT_PASSWORD" {
  type = string
}

variable "TEMPCONTROLLER_MQTT_USER" {
  type = string
}

variable "TEMPCONTROLLER_MQTT_PASSWORD" {
  type = string
}

variable "ZIG2MQTT_MQTT_USER" {
  type = string
}

variable "ZIG2MQTT_MQTT_PASSWORD" {
  type = string
}

variable "FRIGATE_MQTT_USER" {
  type = string
}

variable "FRIGATE_MQTT_PASSWORD" {
  type = string
}

variable "AUTHENTIK_GRAFANA_CLIENTID" {
  type = string
  description = "Grafana client id for OAuth"
}

variable "AUTHENTIK_GRAFANA_SECRET" {
  type = string
  description = "Grafana client secret for OAuth"
}

variable "AUTHENTIK_POSTGRESQL_PASSWORD" {
  type = string
  description = "Authentik PostgreSQL password"
}

variable "FRIGATE_RTSP_USERNAME" {
  type = string
  description = "FRIGATE_RTSP_USERNAME"
}

variable "FRIGATE_RTSP_PASSWORD" {
  type = string
  description = "FRIGATE_RTSP_PASSWORD"
}

variable "CLOUDFLARE_CREDS" {
  type = string
  description = "Json creds for Cloudflared tunnel"
}

variable "CLOUDFLARE_DNS_API_TOKEN" {
  type = string
  description = "Cloudflare DNS API token used by cert manager for ACME DNS-01 challenge"
}

variable "VPN_USERNAME" {
  type = string
  description = "VPN username"
}

variable "VPN_PASSWORD" {
  type = string
  description = "VPN password"
}

variable "MCP_GRAFANA_APIKEY" {
  type = string
  description = "Service account token for Grafana used by grafana-mcp server"
}

variable "UNIFI_DNS_API_KEY" {
  type = string
  description = "Unifi DNS API key"
}

# -----------------------------------------------------------------------------
# vault secrets enable -path=secret -version=2 kv
resource "vault_mount" "kvv2" {
  path    = "secret"
  type    = "kv"
  options = { version = "2" }
}

# -----------------------------------------------------------------------------
# external secrets operator

# vault policy write external-secrets-policy -
#   path "secret/data/*" {
#     capabilities = ["read", "list"]
#   }
resource "vault_policy" "external-secrets-policy" {
  name = "external-secrets-policy"

  policy = <<EOT
path "secret/data/*" {
  capabilities = ["read", "list"]
}
EOT
}

# vault write auth/kubernetes/role/external-secrets-role \
#   bound_service_account_names=external-secrets \
#   bound_service_account_namespaces=external-secrets \
#   policies=external-secrets-policy \
#   ttl=24h
resource "vault_kubernetes_auth_backend_role" "external-secrets" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "external-secrets-role"
  bound_service_account_names      = ["external-secrets"]
  bound_service_account_namespaces = ["external-secrets"]
  token_ttl                        = 86400
  token_policies                   = ["external-secrets-policy"]
}

# -----------------------------------------------------------------------------
# mongodb

# vault policy write mongodb-secrets-policy -
#   path "secret/data/mongodb" {
#     capabilities = ["read", "list"]
#   }
resource "vault_policy" "mongodb-secrets-policy" {
  name = "mongodb-secrets-policy"

  policy = <<EOT
path "secret/data/mongodb" {
  capabilities = ["read", "list"]
}
EOT
}

# vault write auth/kubernetes/role/mongodb-secrets-role \
#   bound_service_account_names=default \
#   bound_service_account_namespaces=mongodb \
#   policies=mongodb-secrets-policy \
#   ttl=24h
resource "vault_kubernetes_auth_backend_role" "mongodb" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "mongodb-secrets-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["mongodb"]
  token_ttl                        = 86400
  token_policies                   = ["mongodb-secrets-policy"]
}

# -----------------------------------------------------------------------------
# node-red

# vault policy write nodered-secrets-policy -
#   path "secret/data/nodered" {
#     capabilities = ["read", "list"]
#   }
resource "vault_policy" "nodered-secrets-policy" {
  name = "nodered-secrets-policy"

  policy = <<EOT
path "secret/data/nodered" {
  capabilities = ["read", "list"]
}
path "secret/data/nodered-cf-api-token" {
  capabilities = ["read", "list"]
}
EOT
}

# vault write auth/kubernetes/role/nodered-secrets-role \
#   bound_service_account_names=nodered \
#   bound_service_account_namespaces=node-red \
#   policies=nodered-secrets-policy \
#   ttl=24h
resource "vault_kubernetes_auth_backend_role" "nodered" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "nodered-secrets-role"
  bound_service_account_names      = ["nodered"]
  bound_service_account_namespaces = ["node-red"]
  token_ttl                        = 86400
  token_policies                   = ["nodered-secrets-policy"]
}

# -----------------------------------------------------------------------------
# cryptoauth

# vault policy write cryptoautomate-secrets-policy -
#   path "secret/data/cryptoautomation" {
#     capabilities = ["read", "list"]
#   }
resource "vault_policy" "cryptoautomate-secrets-policy" {
  name = "cryptoautomate-secrets-policy"

  policy = <<EOT
path "secret/data/cryptoautomation" {
  capabilities = ["read", "list"]
}
EOT
}

# vault write auth/kubernetes/role/cryptoautomation-secrets-role \
#   bound_service_account_names=default \
#   bound_service_account_namespaces=crypto-automation \
#   policies=cryptoautomate-secrets-policy \
#   ttl=24h
resource "vault_kubernetes_auth_backend_role" "cryptoautomation" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cryptoautomation-secrets-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["crypto-automation"]
  token_ttl                        = 86400
  token_policies                   = ["cryptoautomate-secrets-policy"]
}

# -----------------------------------------------------------------------------
# freeradius

resource "vault_policy" "freeradius-secrets-policy" {
  name = "freeradius-secrets-policy"

  policy = <<EOT
path "secret/data/freeradius" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "freeradius" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "freeradius-secrets-role"
  bound_service_account_names      = ["freeradius"]
  bound_service_account_namespaces = ["freeradius"]
  token_ttl                        = 86400
  token_policies                   = ["freeradius-secrets-policy"]
}

# -----------------------------------------------------------------------------
# mqtt

resource "vault_policy" "mqtt-secrets-policy" {
  name = "mqtt-secrets-policy"

  policy = <<EOT
path "secret/data/mqtt" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "mqtt" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "mqtt-secrets-role"
  bound_service_account_names      = ["mqtt-mosquitto"]
  bound_service_account_namespaces = ["mqtt"]
  token_ttl                        = 86400
  token_policies                   = ["mqtt-secrets-policy"]
}

# -----------------------------------------------------------------------------
# zigbee2mqtt

resource "vault_policy" "zig2mqtt-secrets-policy" {
  name = "zig2mqtt-secrets-policy"

  policy = <<EOT
path "secret/data/zig2mqtt" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "zig2mqtt" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "zig2mqtt-secrets-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["zigbee2mqtt"]
  token_ttl                        = 86400
  token_policies                   = ["zig2mqtt-secrets-policy"]
}

# -----------------------------------------------------------------------------
# authentik

resource "vault_policy" "authentik-secrets-policy" {
  name = "authentik-secrets-policy"

  policy = <<EOT
path "secret/data/authentik" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "authentik" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "authentik-secrets-role"
  bound_service_account_names      = ["authentik"]
  bound_service_account_namespaces = ["authentik"]
  token_ttl                        = 86400
  token_policies                   = ["authentik-secrets-policy"]
}

# -----------------------------------------------------------------------------
# frigate

resource "vault_policy" "frigate-secrets-policy" {
  name = "frigate-secrets-policy"

  policy = <<EOT
path "secret/data/frigate" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "frigate" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "frigate-secrets-role"
  bound_service_account_names      = ["frigate"]
  bound_service_account_namespaces = ["frigate"]
  token_ttl                        = 86400
  token_policies                   = ["frigate-secrets-policy"]
}

# -----------------------------------------------------------------------------
# vpn

resource "vault_policy" "vpn-secrets-policy" {
  name = "vpn-secrets-policy"

  policy = <<EOT
path "secret/data/vpn" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "vpn" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vpn-secrets-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["torrent"]
  token_ttl                        = 86400
  token_policies                   = ["vpn-secrets-policy"]
}

# -----------------------------------------------------------------------------
# cloudflared

resource "vault_policy" "cloudflare-secrets-policy" {
  name = "cloudflare-secrets-policy"

  policy = <<EOT
path "secret/data/cloudflare" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "cloudflare" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cloudflare-secrets-role"
  bound_service_account_names      = ["cloudflare"]
  bound_service_account_namespaces = ["cloudflare"]
  token_ttl                        = 86400
  token_policies                   = ["cloudflare-secrets-policy"]
}

# -----------------------------------------------------------------------------
# grafana-mcp

resource "vault_policy" "grafana-mcp-secrets-policy" {
  name = "grafana-mcp-secrets-policy"

  policy = <<EOT
path "secret/data/grafana-mcp" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "grafana-mcp" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "grafana-mcp-secrets-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["grafana-mcp"]
  token_ttl                        = 86400
  token_policies                   = ["grafana-mcp-secrets-policy"]
}

# -----------------------------------------------------------------------------
# vault kv patch secret/nodered hue-token="$HUE_TOKEN"
resource "vault_kv_secret_v2" "nodered" {
  mount     = vault_mount.kvv2.path
  name      = "nodered"
  data_json = jsonencode(
    {
      mqtt-user          = var.NODERED_MQTT_USER
      mqtt-password      = var.NODERED_MQTT_PASSWORD
      hue-token          = var.HUE_TOKEN
      sonos-diningroom-r = var.SONOS_DININGROOM_R
      sonos-diningroom-l = var.SONOS_DININGROOM_L
      sonos-whiskyroom-r = var.SONOS_WHISKYROOM_R
      sonos-whiskyroom-l = var.SONOS_WHISKYROOM_L
      zen-wifi-user      = var.ZEN_WIFI_USER
      zen-wifi-password  = var.ZEN_WIFI_PASSWORD
      unifi-user         = var.UNIFI_USER
      unifi-password     = var.UNIFI_PASSWORD
    }
  )
}

resource "vault_kv_secret_v2" "nodered-cf-api-token" {
  mount     = vault_mount.kvv2.path
  name      = "nodered-cf-api-token"
  data_json = jsonencode(
    {
      dns-api-token = var.CLOUDFLARE_DNS_API_TOKEN
    }
  )
}

# -----------------------------------------------------------------------------
# unifi-dns

resource "vault_policy" "unifi-dns-secrets-policy" {
  name = "unifi-dns-secrets-policy"

  policy = <<EOT
path "secret/data/unifi-dns" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "unifi-dns" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "unifi-dns-secrets-role"
  bound_service_account_names      = ["unifi-dns"]
  bound_service_account_namespaces = ["unifi-dns"]
  token_ttl                        = 86400
  token_policies                   = ["unifi-dns-secrets-policy"]
}

resource "vault_kv_secret_v2" "unifi-dns-api-token" {
  mount     = vault_mount.kvv2.path
  name      = "unifi-dns"
  data_json = jsonencode(
    {
      unifi-dns-api-token = var.UNIFI_DNS_API_KEY
    }
  )
}

# -----------------------------------------------------------------------------
# vault kv patch secret/nodered hue-token="$HUE_TOKEN"

# development
resource "vault_policy" "nodereddev-secrets-policy" {
  name = "nodereddev-secrets-policy"

  policy = <<EOT
path "secret/data/nodereddev" {
  capabilities = ["read", "list"]
}
path "secret/data/nodereddev-cf-api-token" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "nodereddev" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "nodereddev-secrets-role"
  bound_service_account_names      = ["nodereddev"]
  bound_service_account_namespaces = ["node-red-dev"]
  token_ttl                        = 86400
  token_policies                   = ["nodereddev-secrets-policy"]
}

resource "vault_kv_secret_v2" "nodereddev" {
  mount     = vault_mount.kvv2.path
  name      = "nodereddev"
  data_json = jsonencode(
    {
      mqtt-user          = var.NODERED_MQTT_USER
      mqtt-password      = var.NODERED_MQTT_PASSWORD
      hue-token          = var.HUE_TOKEN
      sonos-diningroom-r = var.SONOS_DININGROOM_R
      sonos-diningroom-l = var.SONOS_DININGROOM_L
      sonos-whiskyroom-r = var.SONOS_WHISKYROOM_R
      sonos-whiskyroom-l = var.SONOS_WHISKYROOM_L
      zen-wifi-user      = var.ZEN_WIFI_USER
      zen-wifi-password  = var.ZEN_WIFI_PASSWORD
      unifi-user         = var.UNIFI_USER
      unifi-password     = var.UNIFI_PASSWORD
    }
  )
}

resource "vault_kv_secret_v2" "nodereddev-cf-api-token" {
  mount     = vault_mount.kvv2.path
  name      = "nodereddev-cf-api-token"
  data_json = jsonencode(
    {
      dns-api-token = var.CLOUDFLARE_DNS_API_TOKEN
    }
  )
}

resource "vault_kv_secret_v2" "mongodb" {
  mount     = vault_mount.kvv2.path
  name      = "mongodb"
  data_json = jsonencode(
    {
      init-db-user     = var.MONGODB_INIT_DB_USER
      init-db-password = var.MONGODB_INIT_DB_PASSWORD
    }
  )
}

resource "vault_kv_secret_v2" "cryptoautomation" {
  mount     = vault_mount.kvv2.path
  name      = "cryptoautomation"
  data_json = jsonencode(
    {
      secret-ro = var.COINSPOT_SECRET_RO
      key-ro    = var.COINSPOT_KEY_RO
      bot-name  = var.TELEGRAM_BOT_NAME
      bot-token = var.TELEGRAM_BOT_TOKEN
      chat-id   = var.TELEGRAM_CHAT_ID
    }
  )
}

resource "vault_kv_secret_v2" "freeradius" {
  mount     = vault_mount.kvv2.path
  name      = "freeradius"
  data_json = jsonencode(
    {
      auth-shared-secret = var.AUTH_SHARED_SECRET
    }
  )
}

resource "vault_kv_secret_v2" "mqtt" {
  mount     = vault_mount.kvv2.path
  name      = "mqtt"
  data_json = jsonencode(
    {
      nodered_mqtt_user            = var.NODERED_MQTT_USER
      nodered_mqtt_password        = var.NODERED_MQTT_PASSWORD
      tasmota_mqtt_user            = var.TASMOTA_MQTT_USER
      tasmota_mqtt_password        = var.TASMOTA_MQTT_PASSWORD
      tempcontroller_mqtt_user     = var.TEMPCONTROLLER_MQTT_USER
      tempcontroller_mqtt_password = var.TEMPCONTROLLER_MQTT_PASSWORD
      zig2mqtt_mqtt_user           = var.ZIG2MQTT_MQTT_USER
      zig2mqtt_mqtt_password       = var.ZIG2MQTT_MQTT_PASSWORD
      frigate_mqtt_user            = var.FRIGATE_MQTT_USER
      frigate_mqtt_password        = var.FRIGATE_MQTT_PASSWORD
    }
  )
}

resource "vault_kv_secret_v2" "zig2mqtt" {
  mount     = vault_mount.kvv2.path
  name      = "zig2mqtt"
  data_json = jsonencode(
    {
      mqtt-user     = var.ZIG2MQTT_MQTT_USER
      mqtt-password = var.ZIG2MQTT_MQTT_PASSWORD
    }
  )
}

resource "vault_kv_secret_v2" "authentik" {
  mount     = vault_mount.kvv2.path
  name      = "authentik"
  data_json = jsonencode(
    {
      postgresql-password = var.AUTHENTIK_POSTGRESQL_PASSWORD
    }
  )
}

resource "vault_kv_secret_v2" "frigate" {
  mount     = vault_mount.kvv2.path
  name      = "frigate"
  data_json = jsonencode(
    {
      rtsp-password = var.FRIGATE_RTSP_PASSWORD
      rtsp-username = var.FRIGATE_RTSP_USERNAME
      mqtt-user     = var.FRIGATE_MQTT_USER
      mqtt-password = var.FRIGATE_MQTT_PASSWORD
    }
  )
}

resource "vault_kv_secret_v2" "cloudflare" {
  mount     = vault_mount.kvv2.path
  name      = "cloudflare"
  data_json = jsonencode(
    {
      creds = var.CLOUDFLARE_CREDS
    }
  )
}

resource "vault_kv_secret_v2" "vpn" {
  mount     = vault_mount.kvv2.path
  name      = "vpn"
  data_json = jsonencode(
    {
      username = var.VPN_USERNAME
      password = var.VPN_PASSWORD
    }
  )
}

resource "vault_kv_secret_v2" "grafana-mcp" {
  mount     = vault_mount.kvv2.path
  name      = "grafana-mcp"
  data_json = jsonencode(
    { 
      apikey = var.MCP_GRAFANA_APIKEY
    }
  )
}

