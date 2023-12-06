
## Installation

### Install Ubuntu OS
1. Download server ubuntu ARM64 from https://ubuntu.com/download/server/arm. Currently targetting 22.04.2 LTS.
2. Flash iso to SD card using balenaEtcher
3. Insert SD card into RPi and boot up

### Set password, update
1. ```ssh ubuntu@<ip-address>``` will force change of password
2. reauthenticate
3. sudo apt update
4. sudo apt upgrade

### Set hostname
1. ```sudo hostnamectl set-hostname <rpi-kube-master01>```
2. add 127.0.0.1 <rpi-kube-master01> to /etc/hosts
3. sudo reboot



## Pods not scheduling or replicaset not created

If a deployment has successfully been deployed but the replicaset has not started any pods, it may be due to the controller manager and/or scheduler being unhealthy. 

To verify status and confirm health

Unhealthy:
```
matt@Matthews-Air node-red % kubectl get componentstatuses
NAME                 STATUS      MESSAGE                                                              ERROR
controller-manager   Unhealthy   Get "http://127.0.0.1:10252/healthz": dial tcp 127.0.0.1:10252: connect: connection refused
scheduler            Unhealthy   Get "http://127.0.0.1:10251/healthz": dial tcp 127.0.0.1:10251: connect: connection refused
etcd-0               Healthy     {"health":"true"}
```

### To Fix

Taken from https://stackoverflow.com/questions/64296491/how-to-resolve-scheduler-and-controller-manager-unhealthy-state-in-kubernetes

1. SSH into master node(s)
2. Modify the following files on all master nodes:

```
$ sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml
Delete the line (spec->containers->command) containing this phrase: - --port=0

$ sudo vi /etc/kubernetes/manifests/kube-controller-manager.yaml
Delete the line (spec->containers->command) containing this phrase: - --port=0

$ sudo systemctl restart kubelet.service
```

### To Verify

OK:
```
matt@Matthews-Air node-red % kubectl get componentstatuses     
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-0               Healthy   {"health":"true"}
```

## Master k8s cert expired

```
[authentication.go:64] Unable to authenticate the request due to an error: 
[x509: certificate has expired or is not yet valid, x509: certificate has expired or is not yet valid
```

### Renew master certs

1. ssh into master
2. $<code>master></code> sudo kubeadm certs renew all

```
[renew] Reading configuration from the cluster...
[renew] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[renew] Error reading configuration from the Cluster. Falling back to default configuration

certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
certificate for serving the Kubernetes API renewed
certificate the apiserver uses to access etcd renewed
certificate for the API server to connect to kubelet renewed
certificate embedded in the kubeconfig file for the controller manager to use renewed
certificate for liveness probes to healthcheck etcd renewed
certificate for etcd nodes to communicate with each other renewed
certificate for serving etcd renewed
certificate for the front proxy client renewed
certificate embedded in the kubeconfig file for the scheduler manager to use renewed

Done renewing certificates. You must restart the kube-apiserver, kube-controller-manager, kube-scheduler and etcd, so that they can use the new certificates.
```

### Copy over config for kubectl

Copy the new configuration file created using kubeadm from master to local machine
```
master$ cp /etc/kubernetes/admin.conf master_config
local$ cp master_config ~/.kube/config
local$ kubectl get pods -A 
```
