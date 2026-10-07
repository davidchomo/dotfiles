hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Region screenshot straight to clipboard (no shell UI), complements Super+Shift+S
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"),
    { description = "Utilities: Region screenshot >> clipboard" })

-- Slovak layout: the number row emits +ľščťžýáíé, so bind "send window to workspace" by keycode too
-- (end-4 ships this block commented out; focus-by-keycode is already enabled upstream)
for i = 1, 10 do
    hl.bind("SUPER + ALT + code:" .. (9 + i), function()
        hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
    end)
end

-- Side panel with the most useful shortcuts (toggle)
hl.bind("SUPER + F1", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/helper.sh"),
    { description = "Shell: Toggle shortcut side panel" })

-- CPU turbo boost on/off (/usr/local/bin/cpu-boost, passwordless via /etc/sudoers.d/91-cpu-boost)
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/boost-toggle.sh"),
    { description = "System: Toggle CPU boost" })
