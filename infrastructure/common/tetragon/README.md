
helm repo add cilium https://helm.cilium.io
helm repo update
helm template tetragon cilium/tetragon -n kube-system --values values.yaml > tetragon-stack.yaml

# Install BTF on Ubuntu Node

https://chatgpt.com/c/69621bf6-2d7c-8320-af62-a88114c99b62

Yep — on Ubuntu raspi kernels it’s common for /sys/kernel/btf/vmlinux to be missing because the kernel wasn’t built with CONFIG_DEBUG_INFO_BTF=y (there’s even an Ubuntu bug filed about that).

Fastest fix (without rebuilding the kernel) is: generate an external BTF “vmlinux” file from kernel debug symbols, put it at /var/lib/tetragon/btf/vmlinux, and point Tetragon at it. Tetragon explicitly supports this flow.

Below is a clean, repeatable recipe you can run on one Pi node, then copy the resulting file to the others (as long as they run the exact same uname -r).

## Install tools and enable ddebs
```sudo apt update
sudo apt install -y dwarves llvm lsb-release ubuntu-dbgsym-keyring
```

## Enable the Ubuntu debug symbol repo (ddebs)
```
echo "Types: deb
URIs: http://ddebs.ubuntu.com/
Suites: $(lsb_release -cs) $(lsb_release -cs)-updates $(lsb_release -cs)-proposed
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-dbgsym-keyring.gpg" | \
sudo tee /etc/apt/sources.list.d/ddebs.sources
```
```sudo apt update```

## Install kernel debug symbols
```
uname -r
apt-cache search "linux-image-$(uname -r).*dbgsym" | head -n 20

sudo apt install -y "linux-image-$(uname -r)-dbgsym"
```
## Locate the debug vmlinux and generate a detached BTF file

The debug vmlinux is typically here:
```VMLINUX_DBG="/usr/lib/debug/boot/vmlinux-$(uname -r)"
ls -lh "$VMLINUX_DBG"
```

## Now generate the BTF file that Tetragon can consume:

```sudo mkdir -p /var/lib/tetragon/btf```

### Create a detached BTF blob at the exact path Tetragon looks for
```sudo pahole --btf_encode_detached /var/lib/tetragon/btf/vmlinux "$VMLINUX_DBG"```

### Make it readable (like /sys/kernel/btf/vmlinux would be)
```sudo chmod 444 /var/lib/tetragon/btf/vmlinux
ls -lh /var/lib/tetragon/btf/vmlinux```

This aligns with Tetragon’s documented guidance: if /sys/kernel/btf/vmlinux is missing, provide a BTF file yourself (and Tetragon also checks /var/lib/tetragon/btf).
