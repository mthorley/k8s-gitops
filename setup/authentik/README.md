
# Setup Authentik

## Initial Setup

Admin: https://auth.internal.com/if/flow/initial-setup/

Terraform token: Navigate to admin user | Settings | Token and App Passwords, create a token

Add token to tf env

# Grafana SSO

Uses Authentik to support OIDC federation between Grafana and Authentik.

## Setup Grafana for OIDC support

OAuth client id and secret need to be configured within the Grafana.ini. The ini file is stored in vault and [provisioned via tf](/setup/vault/grafana-kv2.tf) using a [tf template](/setup/vault/grafana-ini-oauth.tftpl).

The ini file was rendered as a k8s secret and mapped into the grafana deployment of the old kube-prometheus stack, which has been retired; grafana now comes from [infrastructure/common/monitoring-system](/infrastructure/common/monitoring-system).

## Setup Authentik via tf for OIDC

Using [terraform](./main.tf), create an oidc provider and also create a new application to link to the oidc provider in Authentik.

## Gotchas

tls_client_ca = /etc/oidc/ca.pem (TBC)
