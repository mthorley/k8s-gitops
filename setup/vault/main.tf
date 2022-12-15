
# vault auth enable kubernetes
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

data "kubernetes_service_account" "vault" {
  metadata {
    name = "vault"
    namespace = "vault"
  }
}

data "kubernetes_secret" "vault" {
  metadata {
    name = data.kubernetes_service_account.vault.default_secret_name
    namespace = "vault"
  }
}

data "kubernetes_config_map" "cacert" {
  metadata {
    name      = "kube-root-ca.crt"
    namespace = "kube-system"
  }
}

# k8s_host="$(kubectl exec vault-0 -n vault -- printenv | grep KUBERNETES_PORT_443_TCP_ADDR | cut -f 2- -d "=" | tr -d " ")"
# k8s_port="443"            
# k8s_cacert="$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)"
# secret_name="$(kubectl get serviceaccount vault -n vault -o jsonpath="{.secrets[*]['name']}")"
# tr_account_token="$(kubectl get secret ${secret_name} -n vault -o jsonpath="{.data.token}" | base64 --decode)"

# vault write auth/kubernetes/config \
#     token_reviewer_jwt="${tr_account_token}" \
#     kubernetes_host="https://${k8s_host}:${k8s_port}" \
#     kubernetes_ca_cert="${k8s_cacert}" \
#     disable_issuer_verification=true \
#     disable_iss_validation=true
resource "vault_kubernetes_auth_backend_config" "config" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = (var.env == "prod" ? var.master_host_port_prod : var.master_host_port_staging)
  kubernetes_ca_cert     = data.kubernetes_config_map.cacert.data["ca.crt"]
  token_reviewer_jwt     = data.kubernetes_secret.vault.data.token
  disable_iss_validation = "true"
}
