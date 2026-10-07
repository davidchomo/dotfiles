-- end-4 disables blur for every window (hyprland/rules.lua); bring it back for the terminal
-- so kitty's background_opacity shows a softly blurred wallpaper like before.
hl.window_rule({ match = { class = "^(kitty)$" }, no_blur = false })

-- Side shortcut panel (Super+F1, custom/scripts/helper.sh): floating, pinned to the right edge
hl.window_rule({
    match   = { class = "^(rice-helper)$" },
    float   = true,
    pin     = true,
    no_blur = false,
    size    = { "380", "monitor_h*0.74" },
    move    = { "monitor_w - 396", "monitor_h*0.07" }, -- 380 px width + 16 px margin (window_w is not final yet when evaluated)
})

-- Desktop widgets (~/.config/desk-widgets): frosted cards, drawn above end-4's wallpaper layer (same Bottom layer)
hl.layer_rule({
    name         = "desk-widgets",
    match        = { namespace = "^desk-widgets$" },
    blur         = true,
    ignore_alpha = 0.3,
    order        = -10, -- lower = drawn above; end-4 wallpaper layer has order 0
})
