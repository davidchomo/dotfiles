-- Hybrid AMD iGPU + NVIDIA dGPU laptops only: let Hyprland use just the AMD GPU and only Mesa's
-- EGL, so the NVIDIA dGPU can runtime-suspend (games still get it via ~/.local/bin/nvidia-run).
-- Enabled only when install.sh detected such a machine and created ~/.config/hypr/gpu-amd
-- (a symlink to /dev/dri/by-path/<AMD>-card; by-path names contain ':' which is the
-- AQ_DRM_DEVICES separator). On any other machine nothing here is set.
local hypr = os.getenv("HOME") .. "/.config/hypr"
if is_file_exists(hypr .. "/gpu-amd") then
    hl.env("AQ_DRM_DEVICES", hypr .. "/gpu-amd")
    hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
end
