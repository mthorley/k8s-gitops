# k8s-gitops

k8s gitops using FluxCD for a home cluster running on raspberry pi's to support IoT and home automation. This repo targets two clusters staging and production and aims to keep a common set of manifests between them, using kustomize to patch values specific for the target cluster.

This is very much WIP.

## How it works

Uses [FluxCD](https://fluxcd.io/docs/) to "synchronise" manifests in this repo to local Pi cluster. The cluster will eventually be consistent with manifests in this repo.

## Configuration

### Clusters

Two physically separate Pi clusters

* Staging
* Production

### Infrastructure

| Workload | Source | Purpose |
| -------- | ------ | ------- |
| [metallb](https://metallb.universe.tf/) | raw manifests | BGP routing from Unifi to k8s for both staging and production clusters |
| [nfs-storage](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/tree/master/charts/nfs-subdir-external-provisioner) | raw manifests | NFS storage |
| [vault](https://www.vaultproject.io/docs/platform/k8s/helm) | helm (TBD) | Secrets management |
 
### Apps

| Workload | Source | Purpose |
| -------- | ------ | ------- |
| mqtt | raw manifests | [MQTT broker (mosquitto)](https://mosquitto.org/) for Tasmota, NodeRed etc |
| rsyslog | raw manifests | Syslog |
| pi-temp-agent | raw manifests | Measure pi temps of each node - used by NodeRed |

## How it fits in 

* Pi's are racked in this https://github.com/mthorley/2u-rack-3dprint-model 
* Uses Unifi to support BGP via terraform - to be published

## TODO

* Add prometheus/grafana monitoring
* Fix up NFS storage as its a single node point of failure
* Get vault auto unsealing or use SOPS
* Publish network management repo for unifi and tasmota
