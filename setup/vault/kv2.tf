
variable "NODERED_MQTT_PASSWORD" {
   type = string
   description = "mqtt password"
   default = ""
}

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
  description = "unifi admin"
}

variable "MONGODB_INIT_DB_USER" {
  type = string
  description = "mongo admin"
}

variable "MONGODB_INIT_DB_PASSWORD" {
  type = string
  description = "mongo admin"
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
# vault kv patch secret/nodered hue-token="$HUE_TOKEN"
resource "vault_kv_secret_v2" "nodered" {
  mount     = vault_mount.kvv2.path
  name      = "nodered"
  data_json = jsonencode(
    {
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
