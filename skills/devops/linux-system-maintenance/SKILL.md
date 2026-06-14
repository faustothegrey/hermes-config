---
name: linux-system-maintenance
description: "Diagnose and safely clean up Linux system health issues: load/RAM/disk/temperature, failed systemd units, package/service removal, and USB storage detection."
tags:
  - linux
  - systemd
  - apt
  - usb-storage
  - health-check
---

# Linux system maintenance

Use this when the user asks whether the machine is stable, wants failed services removed, wants unwanted packages cleaned up, or needs to know whether an external USB disk is detected.

## Operating principles

1. Verify live state with tools before answering. Do not infer system state from memory.
2. Keep the user-facing answer practical: stable / not stable, what is risky, and what was changed.
3. For destructive cleanup, distinguish between the failing component and related components that may still be useful. Prefer removing the narrow problematic install/source first.
4. After removing packages/services, verify with commands that prove the unit/package/binary/path is gone.
5. Avoid stressful disk operations on machines with known SMART risk unless the user explicitly asks.

## System health quick check

Collect a compact snapshot:

```bash
printf '=== date ===\n'; date
printf '\n=== uptime/load ===\n'; uptime
printf '\n=== memory ===\n'; free -h
printf '\n=== disk ===\n'; df -h / /home 2>/dev/null || df -h
printf '\n=== pressure stall ===\n'; for f in /proc/pressure/{cpu,io,memory}; do echo "$f"; cat "$f"; done
printf '\n=== thermal zones ===\n'; for z in /sys/class/thermal/thermal_zone*; do [ -r "$z/temp" ] || continue; printf '%s %s %.1f C\n' "$(basename "$z")" "$(cat "$z/type" 2>/dev/null)" "$(awk "BEGIN{print $(cat "$z/temp")/1000}")"; done
printf '\n=== failed units ===\n'; systemctl --failed --no-pager || true
printf '\n=== recent warnings ===\n'; journalctl -p warning..alert -n 40 --no-pager 2>/dev/null || true
```

If `smartctl` is available and a known-risk disk is involved, use only quick SMART reads, not long tests:

```bash
sudo -n smartctl -H -A /dev/sda 2>/dev/null | sed -n '1,120p'
```

## Removing or permanently disabling an unwanted service safely

Use this for services the user no longer wants because they are noisy, resource-heavy, or failed. Prefer the narrowest permanent disable that stops automatic restarts without deleting the underlying project unless the user explicitly asks for deletion.

For user-level systemd units (`systemctl --user ...`):

```bash
systemctl --user stop UNIT 2>/dev/null || true
systemctl --user disable UNIT
systemctl --user reset-failed UNIT 2>/dev/null || true
systemctl --user daemon-reload
systemctl --user is-enabled UNIT 2>&1 || true
systemctl --user is-active UNIT 2>&1 || true
```

If the user asks for a permanent disable and `systemctl --user mask UNIT` fails because the unit file already exists in `~/.config/systemd/user/`, move the unit file aside instead of fighting systemd:

```bash
unit="$HOME/.config/systemd/user/UNIT"
backup="$HOME/.config/systemd/user/UNIT.disabled"
[ -e "$unit" ] && mv "$unit" "$backup"
systemctl --user daemon-reload
systemctl --user is-enabled UNIT 2>&1 || true   # should report missing/no such file
systemctl --user is-active UNIT 2>&1 || true    # should be inactive
```

Verify with a targeted process check and report the backup path so the user can restore it later.

## Removing a failed service/package safely

1. Identify the exact source of the failed unit:

```bash
systemctl status UNIT --no-pager -l
systemctl list-unit-files --no-pager | awk '/PATTERN/{print}'
dpkg -l | awk '$2 ~ /PATTERN/ {print $1,$2,$3}'
snap list 2>/dev/null | awk '/PATTERN/{print}'
snap services PACKAGE 2>/dev/null || true
```

2. Stop/disable/reset failed state before uninstalling:

```bash
sudo -n systemctl stop UNIT 2>/dev/null || true
sudo -n systemctl disable UNIT 2>/dev/null || true
sudo -n systemctl reset-failed UNIT 2>/dev/null || true
```

3. Remove the correct package source:
   - apt package: `sudo -n apt-get purge -y PKG... && sudo -n apt-get autoremove -y --purge`
   - snap package/service: `sudo -n snap stop --disable SNAP.SERVICE 2>/dev/null || true; sudo -n snap remove SNAP`

4. Verify:

```bash
command -v BINARY || echo 'binary assente'
dpkg -l | awk '$2 ~ /PATTERN/ {print $1,$2,$3}'
snap list PACKAGE 2>/dev/null || echo 'snap package assente'
systemctl list-unit-files --no-pager | awk '/PATTERN/{print}'
systemctl --failed --no-pager || true
```

## Kubernetes cleanup pattern

When the user explicitly asks to remove Kubernetes, remove kube-specific packages and state, but do not automatically remove Docker/containerd unless asked because they may be used independently.

```bash
sudo -n systemctl stop kubelet 2>/dev/null || true
sudo -n systemctl disable kubelet 2>/dev/null || true
sudo -n systemctl reset-failed kubelet 2>/dev/null || true
sudo -n apt-get purge -y kubelet kubeadm kubectl kubernetes-cni cri-tools
sudo -n apt-get autoremove -y --purge
sudo -n rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /etc/cni /opt/cni /var/lib/cni /var/run/kubernetes /run/kubernetes
rm -rf "$HOME/.kube"
```

Verify `kubelet`, `kubeadm`, `kubectl`, and `crictl` are absent and no kube systemd units remain.

## Snap duplicate cleanup pattern

If a failed service belongs to a snap, check whether an apt version of the same app exists. If yes, removing only the snap can be the safer cleanup because the desktop app remains available from apt.

Example: failed `snap.remmina.ssh-agent.service` can be resolved by removing the Remmina snap while leaving apt Remmina installed.

## USB external disk detection

Use this sequence when a user expects an external disk to be connected:

```bash
lsblk -o NAME,TYPE,SIZE,MODEL,SERIAL,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
lsusb
lsusb -t
find /dev/disk/by-id -maxdepth 1 -type l -iname '*usb*' -printf '%f -> %l\n' 2>/dev/null | sort || true
journalctl -k --since '5 minutes ago' --no-pager | grep -Ei 'usb|uas|usb-storage|scsi|sd[a-z]|blk|ntfs|exfat|ext4|i/o error|reset|disconnect|device descriptor|over-current|power' || true
```

Interpretation:
- If no `lsusb` entry, no `/dev/sdX`, no `/dev/disk/by-id/*usb*`, and no kernel USB/storage logs after reconnect, Linux is not seeing the device at the USB layer. Treat it as likely cable/port/power/enclosure/device hardware, not a mount/filesystem issue.
- If USB enumerates but no block device appears, investigate UAS/usb-storage errors and enclosure compatibility.
- If block device appears but is unmounted, then inspect filesystem and mount state.

See `references/2026-06-13-system-cleanup-usb-disk.md` for a concrete session transcript pattern.

## Alert/watchdog notification style

When maintaining local health watchdogs that send system-load alerts, keep notifications concise and action-oriented. If the user asks to reduce noise, emit only the anomalous metric(s) that crossed thresholds (the reasons list), not a full system snapshot, top-process list, or unrelated stats. Full diagnostics can remain in logs or be gathered on demand.

## Pitfalls

- `apt autoremove` may remove packages that are only indirectly related because apt marks them auto-installed. Mention notable removals in the final summary.
- `systemctl --failed` only shows currently failed units; still check package/binary/path state after cleanup.
- Do not claim a USB disk has a filesystem problem until the device is visible as USB/block storage.
- `dmesg` may be permission-denied for non-root users; use `journalctl -k` first.
