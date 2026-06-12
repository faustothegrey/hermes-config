# Linux nouveau MMIO PRIVRING warnings

Use this reference when investigating reports such as:

```text
nouveau 0000:01:00.0: bus: MMIO write of 00000002 FAULT at 4188ac [ PRIVRING ]
```

Observed pattern from a hybrid Intel + NVIDIA laptop:

- System: Ubuntu 22.04, Linux 5.15 generic kernel.
- GPUs: Intel iGPU using `i915`; NVIDIA GK107M / GeForce GT 750M using `nouveau`.
- The warning repeated during boot and when GPU-manager/Xorg probed or woke the NVIDIA dGPU.
- Nearby journal lines included `nouveau ... Enabling HDA controller` followed by the MMIO PRIVRING fault.
- `gpu-manager.service` completed successfully with status 0; the warning was not itself a failed systemd service.
- The NVIDIA dGPU later entered runtime suspend, indicating the driver initialized sufficiently for normal power management.

Investigation checklist:

```bash
journalctl -b --no-pager -k | grep -Ei 'nouveau|nvidia|i915|drm|MMIO|PRIVRING'
systemctl --failed --no-pager
systemctl status gpu-manager.service --no-pager -l || true
lspci -nnk | sed -n '/VGA\|3D\|Display/,/Kernel modules/p'
lsmod | egrep 'nouveau|nvidia|i915|drm' | sort
for d in /sys/class/drm/card*; do
  [ -e "$d/device/vendor" ] || continue
  echo "$d: vendor=$(cat "$d/device/vendor") device=$(cat "$d/device/device") driver=$(basename "$(readlink -f "$d/device/driver" 2>/dev/null)" 2>/dev/null || echo none)"
done
for p in /sys/bus/pci/devices/0000:01:00.0/power/{control,runtime_status,runtime_suspended_time,runtime_active_time}; do
  [ -e "$p" ] && echo "$p=$(cat "$p")"
done
command -v ubuntu-drivers >/dev/null && ubuntu-drivers devices || true
```

Interpretation guidance:

- Do not assume `nouveau` warnings are a systemd service failure. Distinguish kernel log warnings from failed units with `systemctl --failed` and service status.
- On older NVIDIA Kepler mobile GPUs, nouveau may log MMIO/PRIVRING faults when touching private hardware registers. If DRM initialization completes and the machine has no display freezes, black screens, or GPU-dependent failures, this can be noisy but non-urgent.
- If the dGPU is unused and warnings/power draw matter, possible remediation is blacklisting/disabling nouveau for the NVIDIA device. Treat this as a boot/graphics change and confirm with the user first.
- If the user wants to use the NVIDIA GPU, check `ubuntu-drivers devices`; legacy hardware may require an old proprietary driver such as `nvidia-driver-390`. Do not install it automatically without user confirmation because graphics driver changes can affect boot/display.
