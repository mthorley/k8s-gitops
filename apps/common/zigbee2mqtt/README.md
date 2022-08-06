
# Zigbee k8s and stick flash 

## Generate stack for k8s via Helm

Derived from

```
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm template zigbee2mqtt k8s-at-home/zigbee2mqtt -f values.yaml > stack.yaml
```

## Ensure nodeaffinity established 

Label node for affinity

`kubectl label nodes rpi-kube-worker-stg-03 app=zigbee-controller`

Verify labels across nodes

`kubectl get nodes --show-labels`

# Flashing zzh stick

From https://electrolama.com/radio-docs/flash-cc-bsl/

All executed on MacOS

## Download latest firmware

Device is zzh from https://shop.electrolama.com/collections/usb-rf-sticks/products/zzh-multiprotocol-rf-stick which is a USB connected adapter with external antenna based on **CC2652R** chip.

Take the coordinator firmware from zigbee2mqtt recommended https://www.zigbee2mqtt.io/guide/adapters/#recommended - refer to coordindator link.

Download zip contains `cCC2652R_coordinator_20220219.hex` file.

## Download python to flash

From https://electrolama.com/radio-docs/flash-cc-bsl. 

Download and extract cc2538-bsl:

```curl --output cc2538-bsl.zip https://codeload.github.com/JelmerT/cc2538-bsl/zip/master && unzip cc2538-bsl.zip```

Install dependencies

```/usr/bin/python3 -m pip install --user pyserial intelhex```

## Put stick in BSL Mode

From https://electrolama.com/radio-docs/flash-cc-bsl/.

Basically hold down small button on zzh stick before placing in usb socket.

## Verify port on Mac

```ls /dev/tty*```

port will be something like ```/dev/tty.usbserial-1410```

## Flash

To flash, execute the following python

```python3 cc2538-bsl.py -p PORT -evw FIRMWARE```

e.g.

```python3 cc2538-bsl.py -p /dev/tty.usbserial-1410 -evw CC2652R_coordinator_20220219.hex```

### Output

```
matt@Matthews-Air cc2538-bsl-master % python3 cc2538-bsl.py -p /dev/tty.usbserial-1410 -evw ../CC2652R_coordinator_20220219.hex 
Opening port /dev/tty.usbserial-1410, baud 500000
Reading data from ../CC2652R_coordinator_20220219.hex
Your firmware looks like an Intel Hex file
Connecting to target...
CC1350 PG2.0 (7x7mm): 352KB Flash, 20KB SRAM, CCFG.BL_CONFIG at 0x00057FD8
Primary IEEE Address: 00:12:4B:00:23:8D:A5:16
    Performing mass erase
Erasing all main bank flash sectors
    Erase done
Writing 360448 bytes starting at address 0x00000000
Write 104 bytes at 0x00057F988
    Write done                                
Verifying by comparing CRC32 calculations.
    Verified (match: 0xd85fa172)
matt@Matthews-Air cc2538-bsl-master % 
```
