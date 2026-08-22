Envoy Gateway control plane, rendered the same way as ../nginx-gateway (static
manifest committed to git, not a live HelmRelease -- see that directory's
README for why: coordinating CRDs through a HelmRelease was too fragile).

helm template eg oci://docker.io/envoyproxy/gateway-helm --version v1.5.3 -n envoy-gateway-system > envoy-gateway-stack.yaml

The chart's own crds/gatewayapi-crds.yaml is the *standard* Gateway API CRDs
(HTTPRoute, Gateway, etc.) -- those are already owned by
infrastructure/common/gateway-api-crds and must NOT be duplicated here.
Only Envoy's own CRDs, from crds/generated/*.yaml, went into
envoy-gateway-crds.yaml:

helm pull oci://docker.io/envoyproxy/gateway-helm --version v1.5.3 --untar
cat gateway-helm/crds/generated/gateway.envoyproxy.io_*.yaml > envoy-gateway-crds.yaml

The chart has no GatewayClass template (unlike nginx-gateway-fabric's), so
gatewayclass.yaml is hand-written: GatewayClass "envoy",
controllerName gateway.envoyproxy.io/gatewayclass-controller.

No EnvoyProxy parametersRef is set on the GatewayClass yet, so every Gateway
on this class gets a default LoadBalancer Service (MetalLB assigns the IP).
Revisit that (e.g. externalTrafficPolicy: Local) once in wider use.

Current envoy gateway target: v1.5.3
