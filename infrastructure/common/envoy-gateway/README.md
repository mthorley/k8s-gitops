Envoy Gateway control plane, rendered the same way as ../nginx-gateway (static
manifest committed to git, not a live HelmRelease -- see that directory's
README for why: coordinating CRDs through a HelmRelease was too fragile).

helm template eg oci://docker.io/envoyproxy/gateway-helm --version v1.5.3 -n envoy-gateway \
  --set config.envoyGateway.provider.kubernetes.deploy.type=GatewayNamespace \
  > envoy-gateway-stack.yaml

The deploy.type=GatewayNamespace value is not the chart default. By default
("Controller Namespace" mode) Envoy Gateway puts every Gateway's proxy
Deployment/Service into envoy-gateway regardless of which namespace
the Gateway object itself lives in -- unlike nginx-gateway-fabric, which
always places its per-Gateway data-plane pod in the Gateway's own namespace.
GatewayNamespace mode matches that nginx behaviour (proxy pod lives beside
the app it serves) for consistency across the two GatewayClasses. This is a
cluster-wide control-plane setting, not per-Gateway, and adds one
ClusterRole/ClusterRoleBinding (eg-gateway-helm-cluster-infra-manager)
letting the envoy-gateway ServiceAccount create ServiceAccounts/Services/
ConfigMaps/Deployments/DaemonSets/HPAs/PDBs in arbitrary namespaces -- that's
the mechanism, not a bug. It is NOT compatible with Envoy Gateway's "Merged
Gateways" feature; we don't use that (one dedicated Gateway per app), so it
doesn't apply here.
https://gateway.envoyproxy.io/docs/tasks/operations/gateway-namespace-mode/

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
