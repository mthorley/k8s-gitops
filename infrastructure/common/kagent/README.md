# kagent

Pinned to **0.7.0** because the 0.9.x UI ships Next.js 16 whose `@next/swc`
binary uses ARMv8.2-A instructions and crashes with `SIGILL` on the Pi 4
(Cortex-A72) worker nodes. 0.7.0 is the last release before the 0.8.x bump
and uses SQLite instead of PostgreSQL (no PVC required).

The Anthropic API key Secret block is stripped from the rendered manifest
and managed out-of-band as `Secret/kagent-anthropic` in the `kagent`
namespace, key `ANTHROPIC_API_KEY`.

Two image tags are overridden away from the chart defaults:

- `kmcp.image.tag=0.1.9` — chart default is `v0.1.9`, but the registry tag has
  no `v` prefix (see upstream [kmcp#74](https://github.com/kagent-dev/kmcp/issues/74)).
- `querydoc.image.tag=1.1.14` — chart default `1.1.13`'s arm64 manifest is
  mis-built and contains x86-64 binaries, causing `exec format error` on the
  Pi 4. 1.1.14 is the first tag with a correct aarch64 build.

To re-render:

```sh
VERSION=0.7.0
helm template kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
    --version $VERSION \
    --namespace kagent \
    --create-namespace > kagent-crds-stack.yaml

helm template kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --version $VERSION \
    --namespace kagent \
    --set providers.default=anthropic \
    --set providers.anthropic.apiKey=PLACEHOLDER \
    --set providers.anthropic.model=claude-sonnet-4-5 \
    --set kmcp.image.tag=0.1.9 \
    --set querydoc.image.tag=1.1.14 \
    --set agents.argo-rollouts-agent.enabled=false \
    --set agents.cilium-debug-agent.enabled=false \
    --set agents.cilium-manager-agent.enabled=false \
    --set agents.cilium-policy-agent.enabled=false \
    --set agents.helm-agent.enabled=false \
    --set agents.istio-agent.enabled=false \
    --set agents.kgateway-agent.enabled=false \
    --set agents.observability-agent.enabled=false \
    --set agents.promql-agent.enabled=false > kagent-stack.yaml

# strip the placeholder secret block (managed out-of-band)
awk 'BEGIN{skip=0} /^# Source: kagent\/templates\/modelconfig-secret\.yaml$/{skip=1; next} skip && /^---$/{skip=0; next} !skip{print}' \
    kagent-stack.yaml > kagent-stack.yaml.tmp && mv kagent-stack.yaml.tmp kagent-stack.yaml
```
