
# Install NFS on Ubuntu 22.04

## Mount ssd on target node

```
$ sudo mkdir /mnt/ssd
$ sudo mount /dev/sda /mnt/ssd
```

## Install nfs
```
$ sudo apt install nfs-kernel-server
```

## Add to fstab

Ensure mounting on restart:

```
$ cat /etc/mtab | grep sda
```
will output something like:
```/dev/sda /mnt/ssd ext4 rw,relatime 0 0```

add the output to ```/etc/fstab```

```
$ sudo vi /etc/fstab
```

```$ cat /etc/fstab```

```
LABEL=writable	/	ext4	discard,errors=remount-ro	0 1
LABEL=system-boot       /boot/firmware  vfat    defaults        0       1
/dev/sda /mnt/ssd ext4 rw,relatime 0 0
```

## Add to exports

```sudo vi /etc/exports```

```
/mnt     192.168.3.0/24(rw,sync,no_subtree_check)
/mnt/ssd 192.168.3.0/24(rw,sync,no_subtree_check)
/mnt     192.168.1.0/24(rw,sync,no_subtree_check)
/mnt/ssd 192.168.1.0/24(rw,sync,no_subtree_check)
```

## Restart NFS

```
$ sudo exportfs -a
$ sudo systemctl restart nfs-kernel-server
```

## Verify Status
```
$ sudo systemctl status nfs-kernel-server
```

should output
```
● nfs-server.service - NFS server and services
     Loaded: loaded (/lib/systemd/system/nfs-server.service; enabled; vendor preset: enabled)
    Drop-In: /run/systemd/generator/nfs-server.service.d
             └─order-with-mounts.conf
     Active: active (exited) since Thu 2024-01-18 09:56:28 UTC; 22min ago
    Process: 3053 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
    Process: 3054 ExecStart=/usr/sbin/rpc.nfsd (code=exited, status=0/SUCCESS)
   Main PID: 3054 (code=exited, status=0/SUCCESS)
        CPU: 19ms

Jan 18 09:56:28 rpi-kube-worker-03 systemd[1]: Starting NFS server and services...
Jan 18 09:56:28 rpi-kube-worker-03 systemd[1]: Finished NFS server and services.
```

## Install NFS common on all other nodes

```
$ sudo apt install nfs-common -y
```

# Gotchas

## fsnotify Too Many Open Files Error

If the error occurs for the pod appname:

"`appname` failed to create fsnotify watcher: too many open files"

Change the values to

```
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
```

via sysctl

```
sudo sysctl -w fs.inotify.max_user_instances=8192
sudo sysctl -w fs.inotify.max_user_watches=524288
```
