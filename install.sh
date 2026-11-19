#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"

echo "==> Installing Omarchy-full-AI configuration..."

# 1. Ensure required packages & Ghostty-only terminal setup
if command -v pacman >/dev/null 2>&1; then
  for old_term in foot kitty alacritty; do
    if pacman -Qi "$old_term" >/dev/null 2>&1; then
      echo "Removing old terminal: $old_term"
      sudo pacman -Rns --noconfirm "$old_term" || true
    fi
  done

  needed=(ghostty fish starship qt6-shadertools qt6-multimedia-ffmpeg)
  to_install=()
  for pkg in "${needed[@]}"; do
    pacman -Qi "$pkg" >/dev/null 2>&1 || to_install+=("$pkg")
  done
  if ((${#to_install[@]} > 0)); then
    echo "Installing dependencies: ${to_install[*]}"
    sudo pacman -S --needed --noconfirm "${to_install[@]}"
  fi
fi

# 2. Backup helper
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    cp -a "$target" "${target}.bak.${TS}"
  fi
}

mkdir -p ~/.config/{hypr,ghostty/shaders,fish,omarchy/plugins,omarchy/themes,omarchy/defaults,omarchy/backgrounds/blasphemous,opencode,environment.d} ~/.local/share/applications

# 3. Copy Hyprland, Ghostty, Fish, Starship, XDG terminal
backup_if_exists ~/.config/hypr
cp -a "$REPO_DIR"/config/hypr/* ~/.config/hypr/
cp -a "$REPO_DIR"/config/hypr/.luarc.json ~/.config/hypr/

backup_if_exists ~/.config/ghostty/config
cp -a "$REPO_DIR/config/ghostty/config" ~/.config/ghostty/config
if [[ -d "$REPO_DIR/config/ghostty/shaders" ]]; then
  cp -a "$REPO_DIR"/config/ghostty/shaders/* ~/.config/ghostty/shaders/
fi
if [[ -f "$REPO_DIR/config/applications/com.mitchellh.ghostty.desktop" ]]; then
  cp -a "$REPO_DIR/config/applications/com.mitchellh.ghostty.desktop" ~/.local/share/applications/
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database ~/.local/share/applications || true
fi
if [[ -d "$REPO_DIR/config/environment.d" ]]; then
  cp -a "$REPO_DIR"/config/environment.d/* ~/.config/environment.d/
fi

backup_if_exists ~/.config/fish/config.fish
cp -a "$REPO_DIR/config/fish/config.fish" ~/.config/fish/config.fish
cp -a "$REPO_DIR/config/starship.toml" ~/.config/starship.toml
cp -a "$REPO_DIR/config/xdg-terminals.list" ~/.config/xdg-terminals.list

# 4. Copy Omarchy shell, plugins, backgrounds & recompile .qsb shaders if qsb exists
backup_if_exists ~/.config/omarchy/shell.json
cp -a "$REPO_DIR/config/omarchy/shell.json" ~/.config/omarchy/shell.json
cp -a "$REPO_DIR/config/omarchy/shell.toml" ~/.config/omarchy/shell.toml
cp -a "$REPO_DIR"/config/omarchy/defaults/* ~/.config/omarchy/defaults/
cp -a "$REPO_DIR"/config/omarchy/plugins/* ~/.config/omarchy/plugins/
if [[ -d "$REPO_DIR/config/omarchy/themes" ]]; then
  cp -a "$REPO_DIR"/config/omarchy/themes/* ~/.config/omarchy/themes/
fi
cp -a "$REPO_DIR"/config/omarchy/backgrounds/blasphemous/* ~/.config/omarchy/backgrounds/blasphemous/

if [[ -x /usr/lib/qt6/bin/qsb ]]; then
  /usr/lib/qt6/bin/qsb --qt6 -o ~/.config/omarchy/plugins/maxjalo.lock/liquidglass.frag.qsb ~/.config/omarchy/plugins/maxjalo.lock/liquidglass.frag
  /usr/lib/qt6/bin/qsb --qt6 -o ~/.config/omarchy/plugins/maxjalo.background/rain.frag.qsb ~/.config/omarchy/plugins/maxjalo.background/rain.frag
fi

# 5. Copy OpenCode configs & install local MCP servers (preserving existing API key)
EXISTING_KEY=""
if [[ -f ~/.config/opencode/opencode.json ]]; then
  EXISTING_KEY="$(python3 -c 'import json,pathlib; d=json.loads(pathlib.Path.home().joinpath(".config/opencode/opencode.json").read_text()); k=d.get("provider",{}).get("polza",{}).get("options",{}).get("apiKey",""); print("" if k.startswith("{env:") else k)' 2>/dev/null || true)"
  backup_if_exists ~/.config/opencode/opencode.json
fi

if command -v npm >/dev/null 2>&1; then
  mkdir -p ~/.local/share/opencode-mcp
  printf '{"name":"opencode-mcp-servers","private":true}\n' > ~/.local/share/opencode-mcp/package.json
  (cd ~/.local/share/opencode-mcp && NODE_OPTIONS="--dns-result-order=ipv4first" npm install --no-audit --no-fund @modelcontextprotocol/server-sequential-thinking @modelcontextprotocol/server-memory @playwright/mcp) || true
fi

cp -a "$REPO_DIR/config/opencode/cli.json" ~/.config/opencode/cli.json
cp -a "$REPO_DIR/config/opencode/package.json" ~/.config/opencode/package.json
cp -a "$REPO_DIR/config/opencode/opencode.json" ~/.config/opencode/opencode.json
cp -a "$REPO_DIR/config/opencode/agents" ~/.config/opencode/
cp -a "$REPO_DIR/config/opencode/skills" ~/.config/opencode/
cp -a "$REPO_DIR/config/opencode/plugins" ~/.config/opencode/

python3 - "$EXISTING_KEY" <<'PY'
import json, sys, pathlib
p = pathlib.Path.home() / ".config/opencode/opencode.json"
raw = p.read_text().replace("__HOME__", str(pathlib.Path.home()))
d = json.loads(raw)
if sys.argv[1]:
    d["provider"]["polza"]["options"]["apiKey"] = sys.argv[1]
p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
PY

# Ensure forest.jpg is available in ~/Pictures for lock screen
mkdir -p ~/Pictures
if [[ ! -f ~/Pictures/forest.jpg && -f "$REPO_DIR/sddm/maxjalo-glass/forest.jpg" ]]; then
  cp -a "$REPO_DIR/sddm/maxjalo-glass/forest.jpg" ~/Pictures/forest.jpg
fi

# 6. Install SDDM Liquid Glass theme
echo "==> Installing SDDM theme (maxjalo-glass)..."
sudo rm -rf /usr/share/sddm/themes/maxjalo-glass
sudo mkdir -p /usr/share/sddm/themes/maxjalo-glass
sudo cp -a "$REPO_DIR"/sddm/maxjalo-glass/* /usr/share/sddm/themes/maxjalo-glass/
sudo chown -R root:root /usr/share/sddm/themes/maxjalo-glass
sudo chmod 755 /usr/share/sddm/themes/maxjalo-glass
sudo chmod 644 /usr/share/sddm/themes/maxjalo-glass/*
sudo cp -a "$REPO_DIR"/sddm/conf.d/*.conf /etc/sddm.conf.d/
if [[ -f /etc/sddm.conf.d/autologin.conf ]]; then
  sudo mv /etc/sddm.conf.d/autologin.conf /etc/sddm.conf.d/autologin.conf.bak
fi

# 7. Apply live if running inside Hyprland
if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors >/dev/null 2>&1; then
  hyprctl reload || true
  omarchy theme set rainy-forest || true
  omarchy theme bg set ~/.config/omarchy/themes/rainy-forest/backgrounds/0-rain-cat.jpg || true
  omarchy restart shell || true
fi

echo "==> Done! Remember to export POLZA_API_KEY in your shell or set it in ~/.config/opencode/opencode.json if needed."
