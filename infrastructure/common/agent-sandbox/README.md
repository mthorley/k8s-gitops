## Agent Sandbox

https://github.com/kubernetes-sigs/agent-sandbox

Controller plus extensions (SandboxTemplate, SandboxClaim, SandboxWarmPool) in `agent-sandbox-system`.
Sandboxes run under the `gvisor` RuntimeClass, which only schedules onto nodes prepared per
`setup/k8s/ubuntu-gvisor-install.md` and labelled `sandbox.gvisor=true`.

### Upgrade

```
VERSION=v1.0.6
curl -sL -o agent-sandbox-stack.yaml \
  https://github.com/kubernetes-sigs/agent-sandbox/releases/download/${VERSION}/sandbox-with-extensions.yaml
```

### Test

```
kubectl apply -f - <<'EOF'
apiVersion: agents.x-k8s.io/v1beta1
kind: Sandbox
metadata:
  name: hello
  namespace: default
spec:
  podTemplate:
    spec:
      runtimeClassName: gvisor
      containers:
        - name: shell
          image: busybox
          command: ["sh", "-c", "dmesg; sleep 3600"]
EOF
kubectl logs hello
kubectl delete sandbox hello
```
