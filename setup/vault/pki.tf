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
  common_name           = format("%s", var.cert_domain)
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
  common_name = format("%s Intermediate CA", var.cert_domain)
}

// sign intermediate
resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend              = vault_mount.root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name          = var.cert_domain
  exclude_cn_from_sans = true
  ou                   = "k8s"
  organization         = "homes"
  country              = "AU"
  locality             = "Melbourne"
  province             = "VIC"
  revoke               = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
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

  allowed_domains    = [var.cert_domain]
  allow_subdomains   = true
  allow_any_name     = true
  allow_glob_domains = true
  allow_bare_domains = true
  allow_localhost    = true

  require_cn       = false # https://github.com/cert-manager/cert-manager/issues/4965
}

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
  bound_service_account_names      = ["nodered"]
  bound_service_account_namespaces = ["node-red"]
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
  bound_service_account_names      = ["authentik"]
  bound_service_account_namespaces = ["authentik"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}

resource "vault_kubernetes_auth_backend_role" "grafana-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "grafana-issuer-cert-role"
  bound_service_account_names      = ["grafana"]
  bound_service_account_namespaces = ["monitoring"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}
