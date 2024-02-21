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

## Attach Coral TPU

