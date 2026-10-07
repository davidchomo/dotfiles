hl.on("hyprland.start", function ()
    -- Desktop widgets on HDMI-A-1 (clock, calendar, photos, system, Spotify)
    hl.exec_cmd("qs -p ~/.config/desk-widgets")
    -- KDE Connect (Pixel): daemon + tray icon. end-4 without UWSM does not run XDG autostart.
    hl.exec_cmd("kdeconnectd")
    hl.exec_cmd("sleep 3 && kdeconnect-indicator")
end)
