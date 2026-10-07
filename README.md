# dotfiles – G14 (GA401QC) · CachyOS · Hyprland (Lua) + end-4

Stow layout: each directory is a package mirroring `$HOME`. Currently linked by hand
(whole directories / single files are symlinks into this repo). On a new system:
`sudo pacman -S stow && cd ~/dotfiles && stow -t ~ hypr uwsm desk-widgets claude-bridge kitty fish gamemode mangohud bin`

| package | what |
|---|---|
| `hypr` | `~/.config/hypr/custom/` – my overrides on top of end-4 (GPU env, monitors, sk/us + Alt+Shift, touchpad, rules, keybinds, Super+F1 shortcut panel) |
| `uwsm` | `env-hyprland` – AMD-only `AQ_DRM_DEVICES`, Mesa-only EGL (lets the NVIDIA dGPU sleep) |
| `desk-widgets` | Quickshell desktop widgets on HDMI-A-1 (`qs -p ~/.config/desk-widgets`): clock, Google Calendar (iCal), photos from Pixel (KDE Connect), Spotify, system |
| `claude-bridge` | local OpenAI-compatible bridge end-4 sidebar → Claude Code (`claude -p`), user service; end-4 chat look patch (`end4-patch/apply.sh` after end-4 updates) |
| `kitty`, `fish` | terminal (my originals, not end-4's) |
| `gamemode` | gamemode switches power profile to performance while a game runs |
| `mangohud` | in-game overlay (FPS, frametime, CPU/GPU temp+load, VRAM); Shift_R+F12 toggles, Shift_L+F2 logs to ~/benchmarks/mangohud |
| `bin` | `nvidia-run` – run an app on the NVIDIA dGPU (PRIME offload, EGL allowed) |
| `tuning` | `cpu-boost`, `ryzenadj-tune` – **NOT installed** (system-level; ryzenadj at early boot broke the greeter on 2026-10-07, see notes) |

## Not in git (secrets – recreate by hand)
- `~/.config/desk-widgets/secrets/ical-url` – Google Calendar secret iCal address (chmod 600)
- `~/.config/claude-bridge/token` – bridge token, also in end-4 `config.json` → `ai.extraModels[0].extraParams.bridge_token`

## end-4 settings changed in `~/.config/illogical-impulse/config.json` (not tracked, contains the token)
- `appearance.palette`: `type=scheme-tonal-spot`, `accentColor=c2571a`
- `appearance.wallpaperTheming.enableTerminal=false`
- `bar.workspaces.alwaysShowNumbers=true`, `background.widgets.clock.enable=false`
- `ai.extraModels` = Claude Code bridge (`http://localhost:8742/v1/chat/completions`, model `claude-code`)

## Notes
- Curve Optimizer (real undervolt) is rejected by this G14's SMU; temperature cap via ryzenadj worked but must
  never run during early boot. Benchmarks and plan: `~/benchmarks/`.
- System-level settings outside this repo: `asusctl battery limit 80`, `asusctl profile set --ac Balanced --battery Quiet`.
