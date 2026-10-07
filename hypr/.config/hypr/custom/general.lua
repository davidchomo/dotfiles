-- Monitors
hl.monitor({ output = "eDP-1",    mode = "2560x1440@120", position = "0x0",    scale = 1.6 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "1600x0", scale = 1 })

-- Keyboard + touchpad
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

-- External mouse without acceleration (touchpad keeps libinput's adaptive profile)
hl.device({ name = "logitech-g102-lightsync-gaming-mouse", accel_profile = "flat" })
