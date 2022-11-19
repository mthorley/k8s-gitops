# k8s-gitops

k8s gitops using FluxCD for home clusters running on raspberry pi's to support IoT and home automation. This repo targets two clusters: staging and production and aims to keep a common set of manifests between them, using kustomize to patch values specific for the target clusters.

This is very much WIP.

## How it works

Uses [FluxCD](https://fluxcd.io/docs/) to "synchronise" manifests in this repo to local Pi clusters. Each cluster will eventually be consistent with manifests in this repo.

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
| [mqtt](https://mosquitto.org/) | raw manifests | MQTT broker (mosquitto) for Tasmota, Node-RED etc |
| rsyslog | raw manifests | Syslog to capture logs from NAS, UPS etc. |
| pi-temp-agent | raw manifests | Measure temps of each RaspberryPi cluster node - used by NodeRed |
| [node-red](https://nodered.org/) | raw manifests | Node-RED low code for home automation |
| [adguard]() | helm template | AdGuard Home to block ADs, safe search and browsing | 

## How it fits in 

* Pi's are racked in this https://github.com/mthorley/2u-rack-3dprint-model 
* Uses Unifi to support BGP via terraform - to be published

## TODO

General
* Fix up NFS storage as its a single node point of failure
* Decommission MetalLB and migrate to Cilium
* Get vault auto unsealing or use SOPS
* Publish network management repo for unifi and tasmota
* QNAP stats to influx

Backup
 - [ ] Backup data using influxd backup daily
 - [ ] Deploy grafana operator
 - [ ] Remove grafana from monitoring ns
 - [ ] Get datasources, dashboards etc as code
 - [ ] Upgrade influx (will require upgrade of nodered nodes?)
 - [ ] Restore data to influx
 - [ ] Upgrade grafana via operator
 - [ ] Nodered backup to git repo - private
 - [ ] Homeassistant backup 
 - [ ] Secrets backup - manual? 

 - [ ] Rebuild cluster with latest k8s/ubuntu

Maintain
 - [ ] Renovate
