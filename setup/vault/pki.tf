// https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine#step-1-generate-root-ca

//  vault secrets enable pki
resource "vault_mount" "root" {
  path                      = "pki"
  type                      = "pki"
  description               = "Internal Root CA"
  default_lease_ttl_seconds = 315360000 // 10 years
  max_lease_ttl_seconds     = 315360000
}

// generates a new self-signed CA certificate and private key
// vault write -field=certificate pki/root/generate/internal \
//     common_name="example.com" \
//     issuer_name="root-2022" \
//     ttl=87600h > root_2022_ca.crt
resource "vault_pki_secret_backend_root_cert" "root-2023" {
  backend               = vault_mount.root.path
  type                  = "internal"
  common_name           = (var.ENV == "prod" ? format("%s", var.INTERNAL_DOMAIN_PROD) : format("%s", var.INTERNAL_DOMAIN))
  ttl                   = "315360000"
  format                = "pem"
  private_key_format    = "der"
  key_type              = "rsa"
  key_bits              = 4096
  exclude_cn_from_sans  = true
  ou                    = "k8s"
  organization          = "homes"
}

resource "vault_mount" "intermediate" {
  path                      = "pki_int"
  type                      = vault_mount.root.type
  description               = "intermediate"
  default_lease_ttl_seconds = 31536000 // 1 year
  max_lease_ttl_seconds     = 31536000
}

// generate intermediate CA
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  backend     = vault_mount.intermediate.path
  type        = vault_pki_secret_backend_root_cert.root-2023.type
  common_name = format("%s Intermediate CA", (var.ENV == "prod" ? format("%s", var.INTERNAL_DOMAIN_PROD) : format("%s", var.INTERNAL_DOMAIN)))
}

// sign intermediate
resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend              = vault_mount.root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name          = (var.ENV == "prod" ? format("%s", var.INTERNAL_DOMAIN_PROD) : format("%s", var.INTERNAL_DOMAIN))
  exclude_cn_from_sans = true
  ou                   = "k8s"
  organization         = "homes"
  country              = "AU"
  locality             = "Melbourne"
  province             = "VIC"
  revoke               = false
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

# List issuers on the pki_int backend (created when we generate + set_signed)
data "vault_pki_secret_backend_issuers" "pki_int" {
  backend    = vault_mount.intermediate.path
  # Make sure the intermediate has been generated and signed first
  depends_on = [vault_pki_secret_backend_intermediate_set_signed.intermediate]
}

# Configure the default issuer for pki_int
resource "vault_pki_secret_backend_config_issuers" "pki_int" {
  backend = vault_mount.intermediate.path

  # Use the first issuer returned (for a fresh mount this will be your
  # intermediate CA that you just created and set_signed)
  default = data.vault_pki_secret_backend_issuers.pki_int.keys[0]

  # Optional but nice for future rotations:
  # when you rotate/introduce new issuers, this keeps default in sync
  default_follows_latest_issuer = true
}

resource "vault_policy" "issuer-cert-policy" {
  name = "issuer-cert-policy"

  policy = <<EOT
path "pki*"                             { capabilities = ["read", "list"] }
path "pki_int/sign/internal-dot-com"    { capabilities = ["create", "update"] }
path "pki_int/issue/internal-dot-com"   { capabilities = ["create"] }
EOT
}

#vault write pki/roles/example-dot-com \
#    allowed_domains=example.com \
#    allow_subdomains=true \
#    max_ttl=72h

resource "vault_pki_secret_backend_role" "internal-dot-com" {
  backend          = vault_mount.intermediate.path
  name             = "internal-dot-com"
  ttl              = 3600
  allow_ip_sans    = true
  key_type         = "rsa"
#  key_bits         = 4096

  # Use the backend's default issuer (set above)
  # Valid values: "default", an issuer name, or an issuer ID
  issuer_ref = "default"

  allowed_domains    = [(var.ENV == "prod" ? format("%s", var.INTERNAL_DOMAIN_PROD) : format("%s", var.INTERNAL_DOMAIN))]
  allow_subdomains   = true
  allow_any_name     = true
  allow_glob_domains = true
  allow_bare_domains = true
  allow_localhost    = true

  require_cn       = false # https://github.com/cert-manager/cert-manager/issues/4965
}

# -----------------------------------------------------------------------------
# Issuers
resource "vault_kubernetes_auth_backend_role" "issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "issuer-cert-role"
  bound_service_account_names      = ["cert-manager"]
  bound_service_account_namespaces = ["cert-manager"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

resource "vault_kubernetes_auth_backend_role" "jupyter-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "jupyter-issuer-cert-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["jupyter"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

resource "vault_kubernetes_auth_backend_role" "nodered-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "nodered-issuer-cert-role"
  bound_service_account_names      = (var.ENV == "prod" ? ["vault-issuer"] : ["nodered"])  // FIXME: Remove nodered once cluster1 upgraded
  bound_service_account_namespaces = ["node-red"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

# development
resource "vault_kubernetes_auth_backend_role" "nodered-issuer-dev" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "nodered-issuer-cert-role-dev"
  bound_service_account_names      = ["nodered"]
  bound_service_account_namespaces = ["node-red-dev"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

resource "vault_kubernetes_auth_backend_role" "unifi-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "unifi-issuer-cert-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["unifi-controller"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

resource "vault_kubernetes_auth_backend_role" "auth-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "auth-issuer-cert-role"
  bound_service_account_names      = (var.ENV == "prod" ? ["vault-issuer"] : ["authentik"])  // FIXME: Remove authentik once cluster1 upgraded
  bound_service_account_namespaces = ["authentik"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

resource "vault_kubernetes_auth_backend_role" "grafana-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "grafana-issuer-cert-role"
  bound_service_account_names      = ["vault-issuer"]
  bound_service_account_namespaces = ["monitoring"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

resource "vault_kubernetes_auth_backend_role" "adguard-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "adguard-issuer-cert-role"
  bound_service_account_names      = (var.ENV == "prod" ? ["vault-issuer"] : ["default"])  // FIXME: Remove default once cluster1 upgraded
  bound_service_account_namespaces = ["adguard-home"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

resource "vault_kubernetes_auth_backend_role" "torrent-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "torrent-issuer-cert-role"
  bound_service_account_names      = (var.ENV == "prod" ? ["vault-issuer"] : ["default"])  // FIXME: Remove default once cluster1 upgraded
  bound_service_account_namespaces = ["torrent"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}
