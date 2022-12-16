
# Install CNI

Install CLI
https://docs.cilium.io/en/v1.12/gettingstarted/k8s-install-default/#install-the-cilium-cli

```
cilium install
```

```
cilium status
```
should get

```
matt@Matthews-Air cilium % cilium status      
    /¯¯\
 /¯¯\__/¯¯\    Cilium:         OK
 \__/¯¯\__/    Operator:       OK
 /¯¯\__/¯¯\    Hubble:         disabled
 \__/¯¯\__/    ClusterMesh:    disabled
    \__/

Deployment        cilium-operator    Desired: 1, Ready: 1/1, Available: 1/1
DaemonSet         cilium             Desired: 4, Ready: 4/4, Available: 4/4
Containers:       cilium             Running: 4
                  cilium-operator    Running: 1
Cluster Pods:     41/41 managed by Cilium
Image versions    cilium             quay.io/cilium/cilium:v1.12.2@sha256:986f8b04cfdb35cf714701e58e35da0ee63da2b8a048ab596ccb49de58d5ba36: 4
                  cilium-operator    quay.io/cilium/operator-generic:v1.12.2@sha256:00508f78dae5412161fa40ee30069c2802aef20f7bdd20e91423103ba8c0df6e: 1
```

# Install hubble UI

```cilium hubble enable --ui```

should get

```
🔑 Found CA in secret cilium-ca
ℹ️  helm template --namespace kube-system cilium cilium/cilium --version 1.12.2 --set cluster.id=0,cluster.name=kubernetes,encryption.nodeEncryption=false,hubble.enabled=true,hubble.relay.enabled=true,hubble.tls.ca.cert=LS0...0tLQo=,hubble.tls.ca.key=[--- REDACTED WHEN PRINTING TO TERMINAL (USE --redact-helm-certificate-keys=false TO PRINT) ---],hubble.ui.enabled=true,kubeProxyReplacement=disabled,operator.replicas=1,serviceAccounts.cilium.name=cilium,serviceAccounts.operator.name=cilium-operator,tunnel=vxlan
✨ Patching ConfigMap cilium-config to enable Hubble...
🚀 Creating ConfigMap for Cilium version 1.12.2...
♻️  Restarted Cilium pods
⌛ Waiting for Cilium to become ready before deploying other Hubble component(s)...
🚀 Creating Peer Service...
✨ Generating certificates...
🔑 Generating certificates for Relay...
✨ Deploying Relay...
✨ Deploying Hubble UI and Hubble UI Backend...
⌛ Waiting for Hubble to be installed...
ℹ️  Storing helm values file in kube-system/cilium-cli-helm-values Secret
✅ Hubble was successfully enabled!
```
