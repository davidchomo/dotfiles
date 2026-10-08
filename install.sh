#!/usr/bin/env bash
# Install these dotfiles on top of an end-4 (illogical-impulse) Hyprland setup.
#   ./install.sh                 link the default packages and set up this machine
#   ./install.sh kitty fish      additionally link these optional packages
#   ./install.sh --check         only check prerequisites, change nothing
# Existing files are moved to <file>.bak-<date> before being replaced by a symlink.
# Needs no sudo; system-level extras (tuning, greetd fix) are printed at the end.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
DOT="$PWD"
DEFAULT_PKGS=(hypr uwsm desk-widgets claude-bridge gamemode mangohud brave steam bin tuning spotify)
OPTIONAL_PKGS=(kitty fish fastfetch)

c_ok=$'\e[32m'; c_warn=$'\e[33m'; c_err=$'\e[31m'; c_off=$'\e[0m'
ok()   { echo "${c_ok}✔${c_off} $*"; }
warn() { echo "${c_warn}!${c_off} $*"; }
die()  { echo "${c_err}✘${c_off} $*"; exit 1; }

# ---------------------------------------------------------------- prerequisites
command -v pacman >/dev/null || die "Not an Arch-based system (pacman missing)."
[ -f "$HOME/.config/hypr/hyprland.lua" ] || die "Hyprland Lua config not found – install Hyprland ≥ 0.55 and end-4 first (see INSTALL.md)."
[ -d "$HOME/.config/quickshell/ii" ] || die "end-4 (illogical-impulse) not installed – see INSTALL.md step 2."
ok "Hyprland (Lua) + end-4 found"

missing=()
for p in jq uv python mangohud gamemode lib32-gamemode playerctl brightnessctl; do
    pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
done
optional_missing=()
for p in kdeconnect sshfs brave-bin steam; do
    pacman -Qq "$p" >/dev/null 2>&1 || optional_missing+=("$p")
done
[ ${#missing[@]} -eq 0 ] || warn "missing packages: ${missing[*]}  →  sudo pacman -S --needed ${missing[*]}"
[ ${#optional_missing[@]} -eq 0 ] || warn "optional (features using them stay inactive): ${optional_missing[*]}"
[ "${1:-}" = "--check" ] && exit 0
[ ${#missing[@]} -eq 0 ] || die "install the missing packages first."

# ---------------------------------------------------------------- link packages
pkgs=("${DEFAULT_PKGS[@]}")
for a in "$@"; do
    [[ " ${OPTIONAL_PKGS[*]} ${DEFAULT_PKGS[*]} " == *" $a "* ]] || die "unknown package: $a"
    [[ " ${pkgs[*]} " == *" $a "* ]] || pkgs+=("$a")
done
stamp=$(date +%Y%m%d-%H%M%S)
link() {  # link <package> <path relative to $HOME>
    local src="$DOT/$1/$2" dst="$HOME/$2"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then return; fi
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] || [ -L "$dst" ]; then mv "$dst" "$dst.bak-$stamp"; warn "backup: ~/${2}.bak-$stamp"; fi
    ln -s "$src" "$dst"
}
# what each package links (whole directories where nothing else lives inside)
declare -A LINKS=(
    [hypr]=".config/hypr/custom"
    [uwsm]=".config/uwsm/env-hyprland"
    [desk-widgets]=".config/desk-widgets .local/share/applications/rice-settings.desktop"
    [claude-bridge]=".config/claude-bridge .config/systemd/user/claude-bridge.service"
    [gamemode]=".config/gamemode.ini .config/gamemode"
    [mangohud]=".config/MangoHud"
    [brave]=".config/brave-flags.conf"
    [spotify]=".config/spotify-launcher.conf"
    [steam]=".local/bin/steam .local/bin/steam-launch-options .local/bin/steam-launch-options-after-exit .local/share/steam-launch-options/steam_launch_options.py .config/systemd/user/steam-launch-options@.path .config/systemd/user/steam-launch-options@.service"
    [bin]=".local/bin/nvidia-run"
    [tuning]=".config/cpu-boost .config/ryzenadj-tune"
    [kitty]=".config/kitty"
    [fastfetch]=".config/fastfetch"
    [fish]=".config/fish/config.fish"
)
for pkg in "${pkgs[@]}"; do
    for rel in ${LINKS[$pkg]}; do
        [ -e "$DOT/$pkg/$rel" ] || die "repo is missing $pkg/$rel"
        link "$pkg" "$rel"
    done
    ok "linked: $pkg"
done

# ---------------------------------------------------------------- machine setup
# Hyprland local overrides (monitors, mice)
[ -f "$HOME/.config/hypr/custom/local.lua" ] || { cp "$DOT/hypr/.config/hypr/custom/local.lua.example" "$HOME/.config/hypr/custom/local.lua"; warn "created ~/.config/hypr/custom/local.lua – set your monitors there (hyprctl monitors)"; }

# Hybrid AMD iGPU + NVIDIA dGPU? -> Hyprland on AMD only (see hypr/custom/env.lua)
amd_card=""; nv=0
for c in /sys/class/drm/card[0-9]; do
    v=$(cat "$c/device/vendor" 2>/dev/null || true)
    [ "$v" = 0x1002 ] && amd_card=$(basename "$(readlink -f "$c/device")")
    [ "$v" = 0x10de ] && nv=1
done
if [ -n "$amd_card" ] && [ $nv = 1 ] && [ -e "/dev/dri/by-path/pci-$amd_card-card" ]; then
    ln -sfn "/dev/dri/by-path/pci-$amd_card-card" "$HOME/.config/hypr/gpu-amd"
    ok "hybrid AMD+NVIDIA: Hyprland will use the AMD GPU only (after re-login); games: nvidia-run"
else
    rm -f "$HOME/.config/hypr/gpu-amd"
    ok "not a hybrid AMD+NVIDIA machine – GPU tweaks left off"
fi

# Python venvs (calendar widget, Steam launch options)
uv venv -q --allow-existing "$HOME/.local/share/desk-widgets/venv"
uv pip install -q --python "$HOME/.local/share/desk-widgets/venv/bin/python" icalendar recurring-ical-events
uv venv -q --allow-existing "$HOME/.local/share/steam-launch-options/venv"
uv pip install -q --python "$HOME/.local/share/steam-launch-options/venv/bin/python" vdf
mkdir -p -m 700 "$HOME/.config/desk-widgets/secrets"
ok "python environments ready"

# Steam: launch options for all games after Steam exits (one unit per Steam account)
systemctl --user daemon-reload
if [ -d "$HOME/.local/share/Steam/userdata" ]; then
    for id in "$HOME"/.local/share/Steam/userdata/*/; do
        id=$(basename "$id"); [ "$id" = 0 ] && continue
        systemctl --user enable --now "steam-launch-options@$id.path" >/dev/null 2>&1 && ok "Steam account $id: launch options automation on"
    done
else
    warn "Steam not set up yet – after first login run ./install.sh again"
fi

# Claude Code sidebar bridge (optional)
export PATH="$HOME/.local/bin:$PATH"   # official Claude Code installer puts it here
if command -v claude >/dev/null 2>&1; then
    [ -s "$HOME/.config/claude-bridge/token" ] || (umask 077; python3 -I -c 'import secrets; print(secrets.token_urlsafe(32))' > "$HOME/.config/claude-bridge/token")
    systemctl --user enable --now claude-bridge.service >/dev/null 2>&1
    "$HOME/.config/claude-bridge/end4-patch/apply.sh" >/dev/null 2>&1 || warn "end-4 chat-style patch did not apply cleanly (end-4 version differs) – skipped"
    cfg="$HOME/.config/illogical-impulse/config.json"
    if [ -f "$cfg" ] && ! jq -e '.ai.extraModels[]? | select(.model=="claude-code")' "$cfg" >/dev/null; then
        tok=$(cat "$HOME/.config/claude-bridge/token")
        jq --arg t "$tok" '.ai.extraModels = ((.ai.extraModels // []) + [{"api_format":"openai","name":"Claude Code","model":"claude-code","endpoint":"http://localhost:8742/v1/chat/completions","description":"Claude Code on this computer (full permissions)","icon":"spark-symbolic","requires_key":false,"extraParams":{"bridge_token":$t}}])' "$cfg" > "$cfg.new" && mv "$cfg.new" "$cfg" && chmod 600 "$cfg"
        ok "Claude Code added to the end-4 AI sidebar (Super+A, /model claude-code)"
    fi
else
    warn "Claude Code CLI not found – AI sidebar bridge left off"
fi

# end-4 tweaks without a setting of their own (no popups over full-screen games…)
"$DOT/end4-tweaks/apply.sh" | sed 's/^/  end-4: /' || warn "end-4 tweaks not applied"

command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true

cat <<EOF

${c_ok}Done.${c_off} Next steps (see INSTALL.md):
  1. Edit ~/.config/hypr/custom/local.lua (monitors) and log out / in.
  2. Optional, system-level (sudo):
     - greetd login race fix:  sudo install -Dm644 $DOT/system/etc/systemd/system/greetd.service.d/10-wait-for-gpu.conf /etc/systemd/system/greetd.service.d/10-wait-for-gpu.conf
     - CPU boost toggle (Super+Alt+B):  sudo sh ~/.config/cpu-boost/install.sh
     - ryzenadj-tune: ONLY on ASUS G14 GA401Q (refuses elsewhere)
  3. Calendar widget: put your Google Calendar secret iCal URL into ~/.config/desk-widgets/secrets/ical-url
EOF
