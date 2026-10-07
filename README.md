# dotfiles – CachyOS · Hyprland (Lua) + end-4 add-ons

**Install: see [INSTALL.md](INSTALL.md) (`./install.sh`).** Made on an ASUS G14 GA401QC; machine-specific bits are detected or kept in untracked files.

Stow-compatible layout: each directory is a package mirroring `$HOME`; `install.sh` links them (or use `stow`).

| package | what |
|---|---|
| `hypr` | `~/.config/hypr/custom/` – overrides on top of end-4 (sk/us + Alt+Shift, touchpad, rules, keybinds, Super+F1 panel); hybrid-GPU env only if `~/.config/hypr/gpu-amd` exists; monitors/mice in untracked `local.lua` |
| `uwsm` | `env-hyprland` – on hybrid AMD+NVIDIA laptops: AMD-only `AQ_DRM_DEVICES`, Mesa-only EGL (lets the dGPU sleep) |
| `desk-widgets` | Quickshell desktop widgets on the first external monitor or `$DESK_WIDGETS_SCREEN` (`qs -p ~/.config/desk-widgets`): clock, Google Calendar (iCal), photos from Pixel (KDE Connect), Spotify, system |
| `claude-bridge` | local OpenAI-compatible bridge end-4 sidebar → Claude Code (`claude -p`), user service; end-4 chat look patch (`end4-patch/apply.sh` after end-4 updates) |
| `kitty`, `fish` | terminal (my originals, not end-4's) |
| `gamemode` | gamemode switches power profile to performance while a game runs |
| `mangohud` | in-game overlay (FPS, frametime, CPU/GPU temp+load, VRAM); Shift_R+F12 toggles, Shift_L+F2 logs to ~/benchmarks/mangohud |
| `brave` | `brave-flags.conf` – VA-API hardware video decode on the AMD iGPU (Wayland) |
| `steam` | `steam-launch-options` + `steam-launch-options@<account>.path`: after Steam exits, every game without custom options gets `$HOME/.local/bin/nvidia-run gamemoderun mangohud %command%` |
| `bin` | `nvidia-run` – run an app on the NVIDIA dGPU (PRIME offload, EGL allowed) |
| `tuning` | `cpu-boost` (boost toggle, any CPU with `cpufreq/boost`), `ryzenadj-tune` (ASUS G14 GA401Q only – installer refuses elsewhere); both need sudo |

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
  start well after boot (timer: 3 min). Boot failures on 2026-10-07 were a greetd/plymouth race, fixed by `system/` greetd drop-in.
- System-level settings outside this repo: `asusctl battery limit 80`, `asusctl profile set --ac Balanced --battery Quiet`.
