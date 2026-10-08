//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
// Settings app for the rice add-ons (widgets, Claude Code sidebar, games, system).
// Run: qs -p ~/.config/desk-widgets/settings.qml   (Super+Ctrl+I, launcher: "Nastavenia rice")
// Everything is stored in ~/.config/rice/settings.json (RiceSettings.qml) and applied live.
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ApplicationWindow {
    id: app
    title: "Nastavenia rice"
    width: 920
    height: 680
    minimumWidth: 760
    minimumHeight: 560
    visible: true
    onClosing: Qt.quit()

    Material.theme: Material.Dark
    Material.accent: Theme.primary
    Material.primary: Theme.primaryContainer
    Material.background: Theme.c.surface ?? "#1a120e"
    Material.foreground: Theme.text
    color: Theme.c.surface ?? "#1a120e"

    readonly property string home: Quickshell.env("HOME")
    readonly property var w: RiceSettings.widgets
    readonly property var cl: RiceSettings.claude
    readonly property var gm: RiceSettings.games

    // ------------------------------------------------------------------ live system state
    property var sys: ({})
    Process {
        id: sysProc
        command: ["sh", "-c", `
            k=$(dirname $(grep -l '^k10temp$' /sys/class/hwmon/*/name 2>/dev/null | head -1) 2>/dev/null)
            a=$(dirname $(grep -l '^asus$' /sys/class/hwmon/*/name 2>/dev/null | head -1) 2>/dev/null)
            nv=$(cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status 2>/dev/null || echo none)
            printf '{"profile":"%s","boost":"%s","cpu":%s,"fan":"%s","dgpu":"%s","tune":"%s","bridge":"%s"}' \
              "$(powerprofilesctl get 2>/dev/null)" \
              "$(sudo -n /usr/local/bin/cpu-boost status 2>/dev/null || echo none)" \
              "$( [ -n "$k" ] && echo $(( $(cat $k/temp1_input)/1000 )) || echo null)" \
              "$( [ -n "$a" ] && echo "$(cat $a/fan1_input) / $(cat $a/fan2_input) rpm" )" \
              "$nv" \
              "$(systemctl is-active ryzenadj-tune.timer 2>/dev/null)" \
              "$(systemctl --user is-active claude-bridge 2>/dev/null)"`]
        stdout: StdioCollector {
            onStreamFinished: { try { app.sys = JSON.parse(text); } catch (e) {} }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: sysProc.running = true }
    function run(cmd) { Quickshell.execDetached(cmd); refresh.restart(); }
    Timer { id: refresh; interval: 400; onTriggered: sysProc.running = true }

    // write the secret iCal URL via stdin (never on a command line), file mode 600
    Process {
        id: icalWriter
        stdinEnabled: true
        command: ["sh", "-c", `umask 077; mkdir -p "$HOME/.config/desk-widgets/secrets"; head -c 8192 > "$HOME/.config/desk-widgets/secrets/ical-url"`]
        onRunningChanged: if (!running) icalStatus.text = "Uložené ✓ (kalendár sa obnoví do 10 min alebo po kliknutí na ⟳ vo widgete)"
    }

    // ------------------------------------------------------------------ monitors
    // Live state from hyprctl; the choices in ~/.config/rice/monitors.json. Saving writes
    // ~/.config/hypr/custom/monitors.lua (loaded after local.lua, so it wins) and reloads.
    property var mons: []
    property var monPrefs: ({})
    Process {
        id: monProc
        command: ["sh", "-c", "hyprctl monitors -j; printf '\\n---\\n'; cat \"$HOME/.config/rice/monitors.json\" 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("\n---\n");
                try { app.mons = JSON.parse(parts[0]); } catch (e) {}
                try { app.monPrefs = JSON.parse(parts[1] || "{}"); } catch (e) { app.monPrefs = {}; }
            }
        }
    }
    Timer { interval: 10; running: true; onTriggered: monProc.running = true }
    Process {
        id: monWriter
        stdinEnabled: true
        command: ["sh", "-c", `IFS= read -r json; mkdir -p "$HOME/.config/rice"
            printf '%s\n' "$json" > "$HOME/.config/rice/monitors.json"
            f="$HOME/.config/hypr/custom/monitors.lua"; cat > "$f.new" && mv "$f.new" "$f"
            hyprctl reload >/dev/null`]
        onRunningChanged: if (!running) monRefresh.restart()
    }
    Timer { id: monRefresh; interval: 1200; onTriggered: monProc.running = true }

    function monPref(m) {
        const p = app.monPrefs[m.name] ?? {};
        return {
            hz: p.hz ?? Math.round(m.refreshRate),
            vrr: p.vrr ?? 0,
            cm: p.cm ?? (m.colorManagementPreset || "srgb"),
        };
    }
    function monHzOptions(m) {
        const res = m.width + "x" + m.height + "@";
        const hz = m.availableModes.filter(x => x.startsWith(res)).map(x => Math.round(parseFloat(x.slice(res.length))));
        return [...new Set(hz)].sort((a, b) => b - a);
    }
    function setMon(name, key, value) {
        const prefs = JSON.parse(JSON.stringify(app.monPrefs));
        prefs[name] = Object.assign({}, prefs[name] ?? {}, { [key]: value });
        app.monPrefs = prefs;
        const num = v => String(Math.round(v * 100) / 100);
        const lines = ["-- Written by the rice settings app (Ctrl+Super+I → Monitory); loaded after local.lua.",
                       "-- Delete this file to go back to local.lua's monitor settings."];
        for (const m of app.mons) {
            const p = Object.assign(monPref(m), prefs[m.name] ?? {});
            lines.push(`hl.monitor({ output = "${m.name}", mode = "${m.width}x${m.height}@${p.hz}", position = "${m.x}x${m.y}", scale = ${num(m.scale)}, vrr = ${p.vrr}, cm = "${p.cm}" })`);
        }
        monWriter.stdinEnabled = true;
        monWriter.running = true;
        monWriter.write(JSON.stringify(prefs) + "\n" + lines.join("\n") + "\n");
        monWriter.stdinEnabled = false;
    }

    // MangoHud fps_limit list: the chosen value first, Shift_L+F1 cycles through the rest
    function setFpsLimit(v) {
        gm.fpsLimit = v;
        const order = { "60": "60,120,0", "120": "120,60,0", "141": "141,60,0", "144": "144,60,0", "0": "0,60,120" }[v];
        run(["sed", "--follow-symlinks", "-i", `s/^fps_limit=.*/fps_limit=${order}/`, home + "/.config/MangoHud/MangoHud.conf"]);
    }

    // ------------------------------------------------------------------ small building blocks
    component SectionTitle: Label {
        Layout.topMargin: 14
        font.pixelSize: 15
        font.weight: Font.DemiBold
        color: Theme.primary
    }
    component Hint: Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        font.pixelSize: 12
        color: Theme.subtext
    }
    // label (+ optional hint) on the left, the control anchored to the right edge
    component SettingRow: Item {
        property alias label: lbl.text
        property alias hint: hnt.text
        default property alias control: holder.data
        Layout.fillWidth: true
        Layout.preferredWidth: parent ? parent.width : 400
        implicitHeight: Math.max(texts.implicitHeight, holder.childrenRect.height) + 8
        ColumnLayout {
            id: texts
            anchors.left: parent.left
            anchors.right: holder.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Label { id: lbl; font.pixelSize: 14; color: Theme.text; Layout.fillWidth: true; wrapMode: Text.Wrap }
            Label { id: hnt; visible: text !== ""; font.pixelSize: 12; color: Theme.subtext; wrapMode: Text.Wrap; Layout.fillWidth: true }
        }
        Item {
            id: holder
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }
    component Page: ScrollView {
        default property alias body: col.data
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            id: col
            width: parent.width - 48
            x: 24
            spacing: 10
        }
    }

    // ------------------------------------------------------------------ layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // navigation
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: Theme.c.surface_container ?? "#271e1a"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4
                Label {
                    text: "Nastavenia rice"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    color: Theme.text
                    Layout.margins: 8
                    Layout.bottomMargin: 12
                }
                Repeater {
                    model: [
                        { name: "Widgety", icon: "widgets" },
                        { name: "Claude Code", icon: "smart_toy" },
                        { name: "Hry", icon: "sports_esports" },
                        { name: "Monitory", icon: "desktop_windows" },
                        { name: "Systém", icon: "memory" },
                    ]
                    delegate: ItemDelegate {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        highlighted: pages.currentIndex === index
                        onClicked: pages.currentIndex = index
                        contentItem: RowLayout {
                            spacing: 12
                            Icon { name: modelData.icon; size: 22; color: highlighted ? Theme.primary : Theme.subtext }
                            Label { text: modelData.name; font.pixelSize: 15; color: Theme.text; Layout.fillWidth: true }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Hint { text: "Zmeny sa ukladajú a prejavia hneď.\n~/.config/rice/settings.json" }
            }
        }

        StackLayout {
            id: pages
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ============================================================ Widgety
            Page {
                SectionTitle { text: "Widgety na ploche" }
                SettingRow { label: "Hodiny"; Switch { checked: app.w.clock; onToggled: app.w.clock = checked } }
                SettingRow { label: "Kalendár"; Switch { checked: app.w.calendar; onToggled: app.w.calendar = checked } }
                SettingRow { label: "Fotky"; hint: "~/Pictures/Desk, z mobilu cez KDE Connect (↻ vo widgete)"; Switch { checked: app.w.photos; onToggled: app.w.photos = checked } }
                SettingRow { label: "Spotify"; Switch { checked: app.w.spotify; onToggled: app.w.spotify = checked } }
                SettingRow { label: "Systém (teploty, záťaž)"; Switch { checked: app.w.system; onToggled: app.w.system = checked } }

                SectionTitle { text: "Rozloženie" }
                SettingRow {
                    label: "Monitor"
                    hint: "Automaticky = prvý externý monitor"
                    ComboBox {
                        id: screenBox
                        implicitWidth: 220
                        model: ["Automaticky", ...Quickshell.screens.map(s => s.name)]
                        currentIndex: Math.max(0, model.indexOf(app.w.screen))
                        onActivated: app.w.screen = currentIndex === 0 ? "" : currentText
                    }
                }
                SettingRow { label: "Zrkadlovo"; hint: "Vymení ľavý a pravý stĺpec"; Switch { checked: app.w.mirrored; onToggled: app.w.mirrored = checked } }

                SectionTitle { text: "Fotky" }
                SettingRow {
                    label: "Prepnúť fotku každých (s)"
                    SpinBox { from: 5; to: 600; stepSize: 5; editable: true; value: app.w.photoInterval; onValueModified: app.w.photoInterval = value }
                }

                SectionTitle { text: "Kalendár" }
                SettingRow {
                    label: "Ukázať udalosti na najbližších (dní)"
                    SpinBox { from: 1; to: 365; editable: true; value: app.w.calendarDays; onValueModified: app.w.calendarDays = value }
                }
                SettingRow {
                    label: "Najviac udalostí"
                    SpinBox { from: 1; to: 8; value: app.w.calendarItems; onValueModified: app.w.calendarItems = value }
                }
                SettingRow {
                    label: "Tajná iCal adresa"
                    hint: "Google Calendar → Nastavenia → tvoj kalendár → Tajná adresa vo formáte iCal"
                    RowLayout {
                        TextField { id: icalField; implicitWidth: 260; echoMode: TextInput.Password; placeholderText: "https://calendar.google.com/…" }
                        Button {
                            text: "Uložiť"
                            enabled: icalField.text.startsWith("https://")
                            onClicked: {
                                icalWriter.running = true;
                                icalWriter.write(icalField.text.trim() + "\n");
                                icalWriter.stdinEnabled = false;
                                icalField.text = "";
                            }
                        }
                    }
                }
                Hint { id: icalStatus; text: "" }
            }

            // ============================================================ Claude Code
            Page {
                SectionTitle { text: "Claude Code v bočnom paneli (Super+A)" }
                SettingRow {
                    label: "Zapnutý"
                    hint: "Most: " + (app.sys.bridge === "active" ? "beží" : (app.sys.bridge ?? "…"))
                    Switch { checked: app.cl.enabled; onToggled: app.cl.enabled = checked }
                }
                SettingRow {
                    label: "Model"
                    ComboBox {
                        implicitWidth: 280
                        readonly property var values: ["", "fable", "opus", "sonnet", "haiku"]
                        model: ["Predvolený (Claude Code)", "Fable", "Opus", "Sonnet", "Haiku (najrýchlejší)"]
                        currentIndex: Math.max(0, values.indexOf(app.cl.model))
                        onActivated: app.cl.model = values[currentIndex]
                    }
                }
                SettingRow {
                    label: "Oprávnenia"
                    hint: "Čo smie robiť bez pýtania"
                    ComboBox {
                        implicitWidth: 260
                        readonly property var values: ["all", "edit", "read"]
                        model: ["Všetko (aj príkazy)", "Upravovať súbory, bez príkazov", "Iba čítať a hľadať"]
                        currentIndex: Math.max(0, values.indexOf(app.cl.permissions))
                        onActivated: app.cl.permissions = values[currentIndex]
                    }
                }
                SettingRow {
                    label: "Jazyk odpovedí"
                    ComboBox {
                        implicitWidth: 220
                        readonly property var values: ["sk", "en"]
                        model: ["Slovenčina", "English"]
                        currentIndex: Math.max(0, values.indexOf(app.cl.language))
                        onActivated: app.cl.language = values[currentIndex]
                    }
                }
                SettingRow {
                    label: "Štýl odpovedí"
                    ComboBox {
                        implicitWidth: 220
                        readonly property var values: ["short", "detailed"]
                        model: ["Stručne", "Podrobne"]
                        currentIndex: Math.max(0, values.indexOf(app.cl.style))
                        onActivated: app.cl.style = values[currentIndex]
                    }
                }
                SettingRow {
                    label: "Pracovný priečinok"
                    hint: "Kde Claude Code „stojí“ (napr. ~ alebo ~/projekty)"
                    TextField { implicitWidth: 260; text: app.cl.workdir; onEditingFinished: app.cl.workdir = text.trim() || "~" }
                }
                Hint { text: "Zmeny platia od ďalšej otázky. Nová konverzácia v paneli: /clear." }
                Button { text: "Reštartovať most"; onClicked: app.run(["systemctl", "--user", "restart", "claude-bridge"]) }
            }

            // ============================================================ Hry
            Page {
                SectionTitle { text: "Hry" }
                SettingRow {
                    label: "Limit FPS (MangoHud)"
                    hint: "V hre ľavý Shift+F1 prepína medzi limitmi"
                    ComboBox {
                        implicitWidth: 220
                        readonly property var values: ["60", "120", "141", "144", "0"]
                        model: ["60 FPS", "120 FPS", "141 FPS (FreeSync)", "144 FPS", "Bez limitu"]
                        currentIndex: Math.max(0, values.indexOf(app.gm.fpsLimit))
                        onActivated: app.setFpsLimit(values[currentIndex])
                    }
                }
                SettingRow {
                    label: "Steam spúšťacie voľby pre všetky hry"
                    hint: "nvidia-run gamemoderun mangohud %command% – zapíše sa po ukončení Steamu"
                    Switch { checked: app.gm.steamOptions; onToggled: app.gm.steamOptions = checked }
                }
                SettingRow {
                    label: "CPU boost počas hry"
                    hint: app.sys.boost === "none" ? "Vyžaduje cpu-boost (sudo sh ~/.config/cpu-boost/install.sh)"
                                                   : "Gamemode zapne boost pri štarte hry a potom ho vráti"
                    Switch { enabled: app.sys.boost !== "none"; checked: app.gm.boostInGames; onToggled: app.gm.boostInGames = checked }
                }
            }

            // ============================================================ Monitory
            Page {
                SectionTitle { text: "Monitory" }
                Hint { text: "Zmena sa prejaví hneď (Hyprland sa znova načíta). Uložené v ~/.config/hypr/custom/monitors.lua – zmaž ho, ak chceš späť pôvodné nastavenie." }
                Repeater {
                    model: app.mons
                    delegate: ColumnLayout {
                        id: monBox
                        required property var modelData
                        readonly property var m: modelData
                        readonly property var p: app.monPref(m)
                        Layout.fillWidth: true
                        spacing: 6
                        SectionTitle { text: monBox.m.name + "  ·  " + monBox.m.model + "  (" + monBox.m.width + "×" + monBox.m.height + ")" }
                        SettingRow {
                            label: "Obnovovacia frekvencia"
                            hint: "Teraz " + Math.round(monBox.m.refreshRate) + " Hz"
                            ComboBox {
                                implicitWidth: 220
                                readonly property var values: app.monHzOptions(monBox.m)
                                model: values.map(v => v + " Hz")
                                currentIndex: Math.max(0, values.indexOf(monBox.p.hz))
                                onActivated: i => app.setMon(monBox.m.name, "hz", values[i])
                            }
                        }
                        SettingRow {
                            label: "FreeSync / VRR"
                            hint: "Plynulejšie hry bez trhania; „Iba hry“ zapína VRR len pri okne na celú obrazovku"
                            ComboBox {
                                implicitWidth: 220
                                readonly property var values: [0, 2, 1]
                                model: ["Vypnutý", "Iba hry (celá obrazovka)", "Vždy"]
                                currentIndex: Math.max(0, values.indexOf(monBox.p.vrr))
                                onActivated: i => app.setMon(monBox.m.name, "vrr", values[i])
                            }
                        }
                        SettingRow {
                            label: "Farby"
                            hint: "Presýtené farby na monitore so širokým gamutom opraví „Podľa monitora“. HDR iba ak ho monitor naozaj má."
                            ComboBox {
                                implicitWidth: 220
                                readonly property var values: ["srgb", "edid", "wide", "hdr"]
                                model: ["sRGB (predvolené)", "Podľa monitora (EDID)", "Široký gamut", "HDR"]
                                currentIndex: Math.max(0, values.indexOf(monBox.p.cm))
                                onActivated: i => app.setMon(monBox.m.name, "cm", values[i])
                            }
                        }
                    }
                }
            }

            // ============================================================ Systém
            Page {
                SectionTitle { text: "Výkonový profil" }
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: [
                            { id: "power-saver", name: "Quiet", icon: "energy_savings_leaf" },
                            { id: "balanced", name: "Balanced", icon: "airwave" },
                            { id: "performance", name: "Performance", icon: "local_fire_department" },
                        ]
                        delegate: Button {
                            required property var modelData
                            text: modelData.name
                            highlighted: app.sys.profile === modelData.id
                            onClicked: app.run(["powerprofilesctl", "set", modelData.id])
                        }
                    }
                }
                Hint { text: "Hry cez gamemode prepnú na Performance samé a potom sa vráti pôvodný profil." }

                SectionTitle { text: "CPU" }
                SettingRow {
                    label: "CPU boost"
                    hint: app.sys.boost === "none" ? "Nenainštalované: sudo sh ~/.config/cpu-boost/install.sh"
                                                   : "Vypnutý = chladnejšie, max. 3,2 GHz (platí do reštartu, Super+Alt+B)"
                    Switch {
                        enabled: app.sys.boost !== "none" && app.sys.boost !== undefined
                        checked: app.sys.boost === "on"
                        onToggled: app.run(["sudo", "-n", "/usr/local/bin/cpu-boost", checked ? "on" : "off"])
                    }
                }
                SettingRow {
                    label: "Teplotný strop a limity (ryzenadj-tune)"
                    hint: app.sys.tune === "active" ? "Aktívny: Balanced 35 W, strop 85 °C; Performance bez obmedzenia"
                                                    : "Nenainštalovaný (iba ASUS G14: sudo sh ~/.config/ryzenadj-tune/install.sh)"
                    Label { text: app.sys.tune === "active" ? "✓" : "–"; color: Theme.primary; font.pixelSize: 18 }
                }

                SectionTitle { text: "Teraz" }
                SettingRow { label: "Teplota CPU"; Label { text: app.sys.cpu !== null && app.sys.cpu !== undefined ? app.sys.cpu + " °C" : "–"; color: Theme.text } }
                SettingRow { label: "Ventilátory"; Label { text: app.sys.fan || "–"; color: Theme.text } }
                SettingRow {
                    label: "NVIDIA"
                    Label {
                        color: Theme.text
                        text: ({ "suspended": "spí", "active": "zobudená", "none": "nie je" })[app.sys.dgpu] ?? (app.sys.dgpu ?? "–")
                    }
                }
            }
        }
    }
}
