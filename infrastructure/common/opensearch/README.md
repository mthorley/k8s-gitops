Derived from

```
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update
helm template opensearch opensearch/opensearch -f values.yaml > opensearch-stack.yaml
```
