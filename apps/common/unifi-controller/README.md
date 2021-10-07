helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm template unifi k8s-at-home/unifi --set env.TZ="Melbourne/Australia" > unifi-stack.yaml
