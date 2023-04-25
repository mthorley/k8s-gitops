
## Ingress annotations for proxy

  annotations:
    nginx.ingress.kubernetes.io/auth-url: |-
        http://ak-outpost-adguard-outpost.authentik.svc.cluster.local:9000/outpost.goauthentik.io/auth/nginx
    nginx.ingress.kubernetes.io/auth-signin: |-
        https://auth.internal.com/outpost.goauthentik.io/start?rd=$escaped_request_uri
    nginx.ingress.kubernetes.io/auth-response-headers: |-
        Set-Cookie,X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid
    nginx.ingress.kubernetes.io/auth-snippet: |
        proxy_set_header X-Forwarded-Host $http_host;spec:
