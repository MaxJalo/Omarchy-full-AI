---
name: Linux & Arch Sysadmin
description: Diagnose and tune Arch Linux, systemd services, Hyprland, Wayland, PipeWire audio, GPU/drivers, and packages safely
---

## Diagnostics Workflow
- System & boot logs: `journalctl -p 3 -xb` or `journalctl --user -u <unit> -n 50 --no-pager`
- Failed units: `systemctl --failed` and `systemctl --user --failed`
- Hyprland verification: always validate Lua/config edits with `hyprctl reload && hyprctl configerrors`
- Wayland windows/layers: inspect live geometry and classes with `hyprctl clients -j` and `hyprctl layers`
- Package queries: `pacman -Qs <pkg>`, `pacman -Qi <pkg>` (check `Required By` before removing anything)

## Privilege Escalation
- In interactive terminals, use `sudo`.
- From background/agent processes without a TTY, use `pkexec` (triggers the graphical Polkit agent) and batch root commands into a single call when possible.
