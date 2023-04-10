output "intermediate_ca" {
  value = vault_pki_secret_backend_intermediate_set_signed.intermediate
}

#output "config" {
#  value = vault_kv_secret_v2.grafana
#}
