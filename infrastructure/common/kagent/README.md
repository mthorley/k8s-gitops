# kagent

Pinned to **0.7.0** because the 0.9.x UI ships Next.js 16 whose `@next/swc`
binary uses ARMv8.2-A instructions and crashes with `SIGILL` on the Pi 4
(Cortex-A72) worker nodes. 0.7.0 is the last release before the 0.8.x bump
and uses SQLite instead of PostgreSQL (no PVC required).

The Anthropic API key Secret block is stripped from the rendered manifest
and managed out-of-band as `Secret/kagent-anthropic` in the `kagent`
namespace, key `ANTHROPIC_API_KEY`.

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
    --set providers.anthropic.apiKey=PLACEHOLDER > kagent-stack.yaml

# strip the placeholder secret block (managed out-of-band)
awk 'BEGIN{skip=0} /^# Source: kagent\/templates\/modelconfig-secret\.yaml$/{skip=1; next} skip && /^---$/{skip=0; next} !skip{print}' \
    kagent-stack.yaml > kagent-stack.yaml.tmp && mv kagent-stack.yaml.tmp kagent-stack.yaml
```
