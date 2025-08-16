output "intermediate_ca" {
  value = vault_pki_secret_backend_intermediate_set_signed.intermediate
}

# --- ROOT: read current/default issuer (no serials) ---
data "vault_pki_secret_backend_issuer" "root_default" {
  backend    = vault_mount.root.path        # "pki"
  issuer_ref = "default"
}

# --- INTERMEDIATE: read current/default issuer (no serials) ---
data "vault_pki_secret_backend_issuer" "int_default" {
  backend    = vault_mount.intermediate.path  # "pki_int"
  issuer_ref = "default"
}

# Some provider versions expose ca_chain as a list; join to one PEM blob
locals {
  root_ca_pem            = data.vault_pki_secret_backend_issuer.root_default.certificate
  intermediate_ca_pem    = data.vault_pki_secret_backend_issuer.int_default.certificate
  intermediate_chain_pem = (
    try(join("\n", data.vault_pki_secret_backend_issuer.int_default.ca_chain), null)
    != null
    ? join("\n", data.vault_pki_secret_backend_issuer.int_default.ca_chain)
    # Fail
    : ""
  )
}

# Outputs (mark sensitive)
output "root_ca_pem" {
  value     = local.root_ca_pem
  sensitive = true
}

output "intermediate_ca_pem" {
  value     = local.intermediate_ca_pem
  sensitive = true
}

output "intermediate_ca_chain_pem" {
  value     = local.intermediate_chain_pem
  sensitive = true
}

# Optional: write files so you can import into macOS Keychain immediately
resource "local_sensitive_file" "root_ca" {
  filename = "${path.module}/root-ca.pem"
  content  = local.root_ca_pem
}

resource "local_sensitive_file" "int_ca" {
  filename = "${path.module}/intermediate-ca.pem"
  content  = local.intermediate_ca_pem
}

resource "local_sensitive_file" "int_chain" {
  count    = local.intermediate_chain_pem == "" ? 0 : 1
  filename = "${path.module}/intermediate-ca-chain.pem"
  content  = local.intermediate_chain_pem
}
