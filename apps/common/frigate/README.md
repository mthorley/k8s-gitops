## Installation

From https://github.com/blakeblackshear/blakeshome-charts/tree/master/charts/frigate

<pre>
helm template \
  frigate \
  blakeblackshear/frigate \
  -n frigate \
  -f values.yaml > frigate-stack.yaml
</pre>

## Configure GPU on RPi4

As per [Frigate guidance](https://docs.frigate.video/configuration/hardware_acceleration), increase allocated RAM for GPU to at least 128:

```sudo raspi-config```

and reboot

## Ensure nodeaffinity established 

Label node for affinity

`kubectl label nodes rpi-kube-worker-01 app=frigate`

Verify labels across nodes

`kubectl get nodes --show-labels`

## Attach Coral TPU

https://coral.ai/docs/accelerator/get-started/#runtime-on-linux

```
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

sudo apt-get update
```

Install Edge TPU runtime
> sudo apt-get install libedgetpu1-std
