
Enable git integration for projects
```
- name: NODE_RED_ENABLE_PROJECTS
  value: "true"
```

kubectl create secret generic internal-ca-secret -n node-red-dev --from-file=internal-ca-cert.pem=/Users/matt/Downloads/internal-ca-cert.pem
