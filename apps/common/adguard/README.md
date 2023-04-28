
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

The above annotations cause the following nginx errors (which means flux cant sync):

```
2023-04-25 16:06:30	
 > ingress="adguard-home/ingress-adguard"

2023-04-25 16:06:30	
	-------------------------------------------------------------------------------
2023-04-25 16:06:30	
	
2023-04-25 16:06:30	
	nginx: configuration file /tmp/nginx/nginx-cfg1275798087 test failed
2023-04-25 16:06:30	
	nginx: [emerg] unknown directive "spec:" in /tmp/nginx/nginx-cfg1275798087:493
2023-04-25 16:06:30	
	2023/04/25 06:06:30 [emerg] 903#903: unknown directive "spec:" in /tmp/nginx/nginx-cfg1275798087:493
2023-04-25 16:06:30	
	nginx: [warn] the "http2_max_requests" directive is obsolete, use the "keepalive_requests" directive instead in /tmp/nginx/nginx-cfg1275798087:147
2023-04-25 16:06:30	
	2023/04/25 06:06:30 [warn] 903#903: the "http2_max_requests" directive is obsolete, use the "keepalive_requests" directive instead in /tmp/nginx/nginx-cfg1275798087:147
2023-04-25 16:06:30	
	nginx: [warn] the "http2_max_header_size" directive is obsolete, use the "large_client_header_buffers" directive instead in /tmp/nginx/nginx-cfg1275798087:146
2023-04-25 16:06:30	
	2023/04/25 06:06:30 [warn] 903#903: the "http2_max_header_size" directive is obsolete, use the "large_client_header_buffers" directive instead in /tmp/nginx/nginx-cfg1275798087:146
2023-04-25 16:06:30	
	nginx: [warn] the "http2_max_field_size" directive is obsolete, use the "large_client_header_buffers" directive instead in /tmp/nginx/nginx-cfg1275798087:145
2023-04-25 16:06:30	
	2023/04/25 06:06:30 [warn] 903#903: the "http2_max_field_size" directive is obsolete, use the "large_client_header_buffers" directive instead in /tmp/nginx/nginx-cfg1275798087:145
2023-04-25 16:06:30	
	Error: exit status 1
2023-04-25 16:06:30	
	-------------------------------------------------------------------------------
```
