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

-- Settings app for the rice add-ons (widgets, Claude Code sidebar, games, system)
hl.bind("CTRL + SUPER + I", hl.dsp.exec_cmd("qs -p ~/.config/desk-widgets/settings.qml"),
    { description = "App: Rice settings (widgets, Claude Code, games)" })

-- Coucou notch: open the Claude Code chat (its own Ctrl+Alt+Space cannot grab keys on Wayland)
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("coucou --shortcut openChat"),
    { description = "App: Coucou notch chat (Claude Code)" })
hl.bind("SUPER + SHIFT + SPACE", hl.dsp.exec_cmd("coucou --tall"),
    { description = "App: Coucou notch – tall / normal chat" })

-- end-4's left sidebar (AI, anime, translator) is not used: the notch has the chat.
-- Its keys are taken off so it cannot be opened by accident.
for _, keys in ipairs({ "SUPER + A", "SUPER + ALT + A", "SUPER + B", "SUPER + O" }) do
    if hl.unbind then hl.unbind(keys) end
end
