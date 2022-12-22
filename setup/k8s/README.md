
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
