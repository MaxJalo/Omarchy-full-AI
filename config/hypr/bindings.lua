-- Personal keybindings for Hyprland (Windows-inspired + AI-first, bloat-free)

-- === AI & Development ===
o.bind("SUPER + SHIFT + A", "OpenCode", "omarchy-launch-or-focus-tui --app-id=org.omarchy.opencode /home/maxjalo/.opencode/bin/opencode --auto")
o.bind("SUPER + ALT + A", "OpenCode Quick AI", "omarchy-launch-or-focus-tui --app-id=TUI.float /home/maxjalo/.opencode/bin/opencode mini")
o.bind("SUPER + SHIFT + T", "New Ghostty Terminal", "ghostty")

-- === Windows-style Productivity Shortcuts ===
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + R", "App launcher", "omarchy-menu toggle apps")
o.bind("SUPER + I", "System menu", "omarchy-menu toggle root")

-- Win + L -> Lock screen (workspace layout moved to Super+Alt+L)
hl.unbind("SUPER + L")
o.bind("SUPER + L", "Lock screen", "omarchy system lock")
o.bind("SUPER + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- Screenshot & Screenrecording (both Ctrl+Shift+S and Super+Shift+S)
o.bind("CTRL + SHIFT + S", "Screenshot region", "omarchy-capture-screenshot")
o.bind("SUPER + SHIFT + S", "Screenshot region", "omarchy-capture-screenshot")
o.bind("SUPER + ALT + S", "Screen recording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + SHIFT + C", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + SHIFT + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- === Useful Apps (replaces ChatGPT / Maps / X / YouTube bloat) ===
o.bind("SUPER + SHIFT + M", "Gmail", { webapp = "https://mail.google.com/", focus = true })
o.bind("SUPER + SHIFT + D", "Docker TUI", { tui = "omarchy-launch-docker-tui" })
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
