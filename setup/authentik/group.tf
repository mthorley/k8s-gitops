
resource "authentik_user" "matt" {
  username = "matt"
  name = "Matt"
  email = var.EMAIL
  attributes = jsonencode({
    settings = {
      locale = ""
    }
  })
}

resource "authentik_group" "grafana_admin" {
  name         = "grafana_admin"
  users        = [authentik_user.matt.id]
  is_superuser = false
}
