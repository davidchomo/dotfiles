-- GPU: Hyprland uses ONLY the AMD iGPU (eDP-1 + HDMI-A-1 are both wired to it).
-- The NVIDIA dGPU is left alone so it can runtime-suspend (~9 W saved); games still use it via
-- prime-run. Trade-off: the USB-C DP output (NVIDIA) does not work in Hyprland.
-- To bring USB-C back: append ':' .. hypr .. '/gpu-nvidia' below (and in ~/.config/uwsm/env-hyprland), relogin.
-- Symlink because /dev/dri/by-path names contain ':' (the AQ_DRM_DEVICES separator):
--   ~/.config/hypr/gpu-amd    -> /dev/dri/by-path/pci-0000:04:00.0-card (AMD:    eDP-1, HDMI-A-1)
--   ~/.config/hypr/gpu-nvidia -> /dev/dri/by-path/pci-0000:01:00.0-card (NVIDIA: DP-1 / USB-C)
local hypr = os.getenv("HOME") .. "/.config/hypr"
hl.env("AQ_DRM_DEVICES", hypr .. "/gpu-amd")

-- Only Mesa EGL in the session (same as ~/.config/uwsm/env-hyprland): stops libEGL_nvidia from
-- being loaded into Hyprland/apps and keeping the dGPU awake. Use `nvidia-run <app>` to undo per app.
hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
