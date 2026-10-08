hl.on("hyprland.start", function ()
    -- Desktop widgets on the external monitor (clock, calendar, photos, system, Spotify)
    hl.exec_cmd("qs -p ~/.config/desk-widgets")
    -- KDE Connect (Pixel): daemon + tray icon. end-4 without UWSM does not run XDG autostart.
    hl.exec_cmd("kdeconnectd")
    hl.exec_cmd("sleep 3 && kdeconnect-indicator")
    -- Coucou: the notch island with the Claude Code chat (only if installed)
    hl.exec_cmd("command -v coucou >/dev/null && coucou")
end)
