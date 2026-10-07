pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colors follow end-4's generated Material You palette (live: changes with the wallpaper/accent).
Singleton {
    id: root

    property var c: ({})

    readonly property color card: Qt.alpha(c.surface_container ?? "#271e1a", 0.72)
    readonly property color cardBorder: Qt.alpha(c.outline_variant ?? "#52443c", 0.55)
    readonly property color track: Qt.alpha(c.surface_container_highest ?? "#3d322d", 0.9)
    readonly property color text: c.on_surface ?? "#f1dfd8"
    readonly property color subtext: c.on_surface_variant ?? "#d7c2b9"
    readonly property color primary: c.primary ?? "#ffb694"
    readonly property color primaryContainer: c.primary_container ?? "#713718"
    readonly property color onPrimaryContainer: c.on_primary_container ?? "#ffdbcc"
    readonly property color tertiary: c.tertiary ?? "#d1c88f"
    readonly property color warn: c.error ?? "#ffb4ab"

    readonly property string font: "Google Sans Flex"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string icons: "Material Symbols Rounded"
    readonly property int radius: 26
    readonly property int pad: 22

    // Monitor the widgets go to: $DESK_WIDGETS_SCREEN if set (e.g. "HDMI-A-1"), otherwise the
    // first external monitor (not a laptop panel eDP-*/LVDS-*), otherwise the first screen.
    readonly property string screenName: RiceSettings.widgets.screen !== "" ? RiceSettings.widgets.screen
                                                                           : (Quickshell.env("DESK_WIDGETS_SCREEN") ?? "")
    readonly property var screen: {
        const all = Quickshell.screens;
        if (screenName !== "")
            for (const s of all) if (s.name === screenName) return s;
        for (const s of all) if (!/^(eDP|LVDS|DSI)/.test(s.name)) return s;
        return all.length > 0 ? all[0] : null;
    }

    FileView {
        id: colors
        path: Quickshell.env("HOME") + "/.local/state/quickshell/user/generated/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.c = JSON.parse(colors.text()); } catch (e) { console.warn("colors.json:", e); }
        }
    }
}
