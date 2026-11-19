---
name: QML & Quickshell
description: Build, style, and debug Quickshell bars, panels, lock screens, SDDM Qt6 themes, and .qsb shaders on Omarchy/Hyprland
---

## Architecture on this machine
- Omarchy shell source (READ-ONLY): `/usr/share/omarchy/shell/`
- User shell config: `~/.config/omarchy/shell.json` and `~/.config/omarchy/shell.toml`
- User shell plugins: `~/.config/omarchy/plugins/<username>.<name>/`
- SDDM theme: `/usr/share/sddm/themes/maxjalo-glass/` (configured in `/etc/sddm.conf.d/99-omarchy-login.conf`)

## Qt 6 Shader Rules (Critical)
- Qt 6 `ShaderEffect` does **not** accept inline GLSL strings. Always write Vulkan-style GLSL 440 (`#version 440`, `layout(std140, binding = 0) uniform buf { mat4 qt_Matrix; float qt_Opacity; ... };`) and compile with `/usr/lib/qt6/bin/qsb --qt6 -o effect.frag.qsb effect.frag`.
- Pass `Qt.resolvedUrl("effect.frag.qsb")` to `ShaderEffect.fragmentShader`.
- For backdrop blur behind a floating pill (`ShaderEffectSource` -> `MultiEffect` -> `ShaderEffect`), ensure `sourceRect` includes `root.width`, `root.height`, and parent position dependencies so `mapToItem` updates reactively during window resize and animations.

## Bar Widget Color Rules
- Always bind widget text/icon color to `bar ? bar.barForeground : Color.foreground` (or omit `foreground:` on `WidgetButton` / `BarIconButton` so it inherits `bar.barForeground` automatically). Never hardcode `Color.foreground` on bar widgets, or they will stop adapting when the bar switches to transparent mode.

## Testing & Reloading
- Hot-reload bar/widget plugins: `omarchy-shell shell rescanPlugins`
- Full shell restart (needed for `keepLoaded: true` services like `maxjalo.lock` or full-bar swaps): `omarchy restart shell`
- Test SDDM Qt6 theme safely without logging out: `sddm-greeter-qt6 --test-mode --theme <path>`
