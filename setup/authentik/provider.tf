terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      version = "2023.3.0"
    }
  }
}

provider "authentik" {
  url = (var.ENV=="prod") ? "https://auth.${var.INTERNAL_DOMAIN_PROD}" : "https://auth.${var.INTERNAL_DOMAIN}"
}
