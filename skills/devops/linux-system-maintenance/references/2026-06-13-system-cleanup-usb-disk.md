# 2026-06-13 system cleanup and USB disk triage

Session-specific pattern captured for future Linux maintenance work.

## Health check findings

Useful commands combined:

```bash
uptime
free -h
df -h / /home
for f in /proc/pressure/{cpu,io,memory}; do echo "$f"; cat "$f"; done
systemctl --failed --no-pager
journalctl -p warning..alert -n 40 --no-pager
sudo -n smartctl -H -A /dev/sda
```

Interpretation used:
- Low CPU load and available memory mean the machine can be usable even if not fully healthy.
- Failed units and SMART risk should be separated in the answer: immediate operability vs. long-term risk.
- On this host, avoid long SMART/self-tests or disk-stress operations because `/dev/sda` has many reallocated sectors and pending sectors.

## Kubernetes removal pattern actually used

Initial state: `kubelet.service` was enabled and crash-looping every ~10 seconds because `/var/lib/kubelet/config.yaml` was missing. Packages present: `kubeadm`, `kubectl`, `kubelet`, `kubernetes-cni`, `cri-tools`. Docker/containerd were also installed but intentionally left alone.

Commands used:

```bash
sudo -n systemctl stop kubelet 2>/dev/null || true
sudo -n systemctl disable kubelet 2>/dev/null || true
sudo -n systemctl reset-failed kubelet 2>/dev/null || true
sudo -n apt-get purge -y kubelet kubeadm kubectl kubernetes-cni cri-tools
sudo -n apt-get autoremove -y --purge
sudo -n rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /etc/cni /opt/cni /var/lib/cni /var/run/kubernetes /run/kubernetes
rm -rf "$HOME/.kube"
```

Verification used:

```bash
for c in kubelet kubeadm kubectl crictl; do command -v "$c" || echo "$c assente"; done
systemctl list-unit-files --no-pager | awk '/kube|kubernetes|etcd|cri-o/{print}'
systemctl --failed --no-pager
```

Lesson: user asked to remove Kubernetes “senza paure”, but Docker/containerd were not removed because they are not Kubernetes-specific and can be useful independently.

## Remmina snap ssh-agent cleanup pattern

Failed unit: `snap.remmina.ssh-agent.service`. System had both snap Remmina and apt Remmina installed.

Safe cleanup chosen:

```bash
sudo -n snap stop --disable remmina.ssh-agent 2>/dev/null || true
sudo -n snap remove remmina
sudo -n systemctl reset-failed snap.remmina.ssh-agent.service 2>/dev/null || true
```

Verification:

```bash
snap list remmina 2>/dev/null || echo 'snap remmina assente'
systemctl list-unit-files --no-pager | awk '/snap\.remmina|remmina/{print}'
systemctl --failed --no-pager
dpkg -l | awk '$2 ~ /remmina/ {print $1,$2,$3}'
```

Lesson: removing the snap fixed the failed service while preserving the apt desktop application.

## USB external disk triage pattern

When user expected an external USB disk, commands used:

```bash
lsblk -o NAME,TYPE,SIZE,MODEL,SERIAL,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
lsusb
lsusb -t
find /dev/disk/by-id -maxdepth 1 -type l -iname '*usb*' -printf '%f -> %l\n' 2>/dev/null | sort || true
journalctl -k --since '5 minutes ago' --no-pager | grep -Ei 'usb|uas|usb-storage|scsi|sd[a-z]|blk|ntfs|exfat|ext4|i/o error|reset|disconnect|device descriptor|over-current|power' || true
```

Findings:
- No `/dev/sdb` or equivalent.
- No `/dev/disk/by-id/*usb*`.
- `lsusb` showed only internal webcam/bluetooth, audio USB, and hubs.
- No kernel USB/storage messages after reconnect.
- `dmesg` was permission-denied, so `journalctl -k` was the useful source.

Conclusion pattern: if the device does not appear in `lsusb`, block devices, by-id, or kernel logs after reconnect, treat it as hardware/electrical/cable/enclosure/power, not a mount or filesystem issue.
