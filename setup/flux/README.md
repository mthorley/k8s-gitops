# Install flux CLI

brew install fluxcd/tap/flux

# Check k8s version

flux check --pre

# Fresh cluster bootstrap

`install-flux-production.sh` (or `-staging.sh`) 
-- creates the `flux-system` namespace and the `cluster-vars` Secret (domains -- kept out of git; 
-- then runs `flux bootstrap`. 

The Secret is created first so there's no race with Flux's first reconcile of `infrastructure`/`apps` and several other Kustomizations, which read it via `postBuild.substituteFrom`.
