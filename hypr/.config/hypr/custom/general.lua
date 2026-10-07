-- Keyboard + touchpad (portable). Monitors and per-device settings live in local.lua.
hl.config({
    input = {
        kb_layout = "sk,us",
        kb_options = "grp:alt_shift_toggle",
        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
        },
    },
})

-- machine-specific overrides (monitors, mice …), not in git
if is_file_exists(HOME .. "/.config/hypr/custom/local.lua") then
    require("custom.local")
end
