-- macOS-inspired smooth look'n'feel and fluid animations for Hyprland

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = { top = 2, right = 8, bottom = 8, left = 8 },
    border_size = 2,
  },

  decoration = {
    rounding = 12,
    dim_inactive = true,
    dim_strength = 0.08,

    blur = {
      enabled = true,
      size = 7,
      passes = 3,
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
    },

    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
      color = "rgba(00000048)",
    },
  },
})

-- Silky macOS spring-like curves & animations
hl.curve("macEase", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
hl.curve("macSpring", { type = "bezier", points = { { 0.22, 1.12 }, { 0.36, 1.0 } } })
hl.curve("macSoft", { type = "bezier", points = { { 0.25, 0.8 }, { 0.25, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4.2, bezier = "macEase" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.0, bezier = "macSpring", style = "popin 86%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.6, bezier = "macEase", style = "popin 88%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.2, bezier = "macEase" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.2, bezier = "macSoft" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5, bezier = "macEase", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.2, bezier = "macEase", style = "slidevert" })
