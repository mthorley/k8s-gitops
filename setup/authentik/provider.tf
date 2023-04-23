terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      version = "2023.3.0"
    }
  }
}

provider "authentik" {
  url   = "https://auth.${var.INTERNAL_DOMAIN}"
}
