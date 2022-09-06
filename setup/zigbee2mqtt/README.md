
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

Downloaded zip contains `cCC2652R_coordinator_20220219.hex` file.

## Download python to flash

From https://electrolama.com/radio-docs/flash-cc-bsl. 

Download and extract cc2538-bsl:

```curl --output cc2538-bsl.zip https://codeload.github.com/JelmerT/cc2538-bsl/zip/master && unzip cc2538-bsl.zip```

Install dependencies

```/usr/bin/python3 -m pip install --user pyserial intelhex```

## Put stick in BSL Mode

From https://electrolama.com/radio-docs/flash-cc-bsl/.

Basically hold down small button on zzh stick before placing in usb socket and release once in the socket.

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

### To test the flashing has worked

See "How can I check if I've flashed the firmware correctly?" in https://electrolama.com/radio-docs/troubleshooting/

Run from RPi
```
ssh <user>@192.168.3.113
python3 znp-uart-test.py
```

should return

```
ubuntu@rpi-kube-worker-stg-03:~$ python3 znp-uart-test.py 
Got 7 bytes in response to PING command: b'\xfe\x02a\x01Y\x06='
PASS|OK
```

# Device Pairing

Ensure the device joining is enabled in the ui by clicking the "Permit Join (All)" button. This will allow any device to join within 255 seconds after which it will disable.

[Zigbee2Mqtt UI](./device_ui.png)

## Philips Hue Motion Sensor

Use a pin or phone sim removal device to reset the device on the back. Hold this down for over 5 seconds and then release. 

## Aqara Window Sensor

Press the small button on the base of the larger sensor for over 5 seconds and then release.

## Mercator Ikuu Outdoor Socket

Press the left (or right) switch down for over 7 seconds, and the red light will start to flash to pair.

If the device is not recognised with an error similar to

```
Device 'Pool Switch A' with Zigbee model 'TS011F' and manufacturer name '_TZ3210_7jnk7l3k' is NOT supported, please follow https://www.zigbee2mqtt.io/advanced/support-new-devices/01_support_new_devices.html
```

Then update the ```configuration.yaml``` to contain the following ```external_converters``` fragment.

This is based on https://community.home-assistant.io/t/mercator-ikuu-double-outdoor-powerpoint/343779. 

```
    advanced:
      ...
      pan_id: 8035
      rtscts: false
    external_converters:
      - SPP02GIP.js
    experimental:
      new_api: true
```

And add the [SPP02GIP.js](../../apps/common/zigbee2mqtt/SPP02GIP.js) file to the container /apps directory next to the ```configuration.yaml``` file.

# Troubleshooting

## Error: SRSP - ZDO - mgmtPermitJoinReq after 6000ms

After period of stable running (approx 30 days), get the above error.

### Workaround (not fix)

- Restarting zigbee2mqtt does not fix
- Replugging usb stick **does** fix 

zigbee2mqtt version: `koenkk/zigbee2mqtt:1.24.0`

zzh firmware version: `CC2652R_coordinator_20220219.hex`

Some discussion here https://github.com/Koenkk/zigbee2mqtt/issues/5015
