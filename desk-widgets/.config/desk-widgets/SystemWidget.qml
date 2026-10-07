import QtQuick
import Quickshell
import Quickshell.Io

// System card: CPU / AMD iGPU / NVIDIA dGPU / RAM / fans / battery,
// streamed from scripts/sysinfo.py (the dGPU is never woken up just to read it).
DeskWindow {
    id: root
    contentWidth: 460
    contentHeight: 520

    property var s: null

    Process {
        id: stats
        command: ["python3", "-I", Quickshell.env("HOME") + "/.config/desk-widgets/scripts/sysinfo.py"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { root.s = JSON.parse(line); } catch (e) {}
            }
        }
        // keep the stream alive if the script ever dies
        onRunningChanged: if (!running) restart.start()
    }
    Timer { id: restart; interval: 5000; onTriggered: stats.running = true }

    function deg(v) { return v === null || v === undefined ? "–" : Math.round(v) + "°"; }

    readonly property var dg: s ? s.dgpu : null
    readonly property bool dgActive: dg !== null && dg.state === "active"

    Card {
        anchors.fill: parent

        Row {
            id: header
            x: Theme.pad
            y: Theme.pad - 4
            spacing: 10
            Icon { name: "monitor_heart"; color: Theme.primary; size: 24 }
            Text {
                text: "Systém"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 20
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // rows spread evenly over the remaining height
        Column {
            id: rows
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: Theme.pad
            anchors.topMargin: 20
            readonly property int n: 6
            spacing: (height - n * 37) / (n - 1)

            StatRow {
                width: rows.width
                icon: "memory"; label: "CPU"
                value: root.s ? root.s.cpu.load + " %   " + root.deg(root.s.cpu.temp) : "–"
                fraction: root.s ? root.s.cpu.load / 100 : 0
                hot: root.s !== null && root.s.cpu.temp >= 85
            }
            StatRow {
                width: rows.width
                icon: "developer_board"; label: "GPU · AMD"
                value: root.s ? (root.s.igpu.load ?? "–") + " %   " + root.deg(root.s.igpu.temp) : "–"
                fraction: root.s && root.s.igpu.load !== null ? root.s.igpu.load / 100 : 0
                hot: root.s !== null && root.s.igpu.temp >= 85
            }
            StatRow {
                width: rows.width
                icon: root.dgActive ? "bolt" : "bedtime"; label: "GPU · NVIDIA"
                value: !root.dg ? "–" : root.dgActive ? ((root.dg.util ?? "–") + " %   " + root.deg(root.dg.temp)) : root.dg.state === "idle" ? "nečinná" : "spí"
                fraction: root.dgActive && root.dg.util !== undefined ? root.dg.util / 100 : 0
                hot: root.dgActive && root.dg.temp >= 85
            }
            StatRow {
                width: rows.width
                icon: "memory_alt"; label: "RAM"
                value: root.s ? root.s.ram.used.toFixed(1) + " / " + Math.round(root.s.ram.total) + " GB" : "–"
                fraction: root.s ? root.s.ram.used / root.s.ram.total : 0
            }
            StatRow {
                width: rows.width
                icon: "mode_fan"; label: "Ventilátory"
                value: root.s && root.s.fans.cpu !== null ? root.s.fans.cpu + " · " + root.s.fans.gpu + " rpm" : "–"
                fraction: root.s && root.s.fans.cpu !== null ? Math.max(root.s.fans.cpu, root.s.fans.gpu) / 7000 : 0
            }
            StatRow {
                width: rows.width
                icon: !root.s ? "battery_unknown"
                    : root.s.battery.status === "Charging" ? "battery_charging_full"
                    : root.s.battery.pct > 80 ? "battery_full"
                    : root.s.battery.pct > 40 ? "battery_5_bar"
                    : root.s.battery.pct > 15 ? "battery_2_bar" : "battery_alert"
                label: "Batéria"
                value: root.s ? root.s.battery.pct + " %" : "–"
                fraction: root.s ? root.s.battery.pct / 100 : 0
                hot: root.s !== null && root.s.battery.pct <= 15 && root.s.battery.status === "Discharging"
            }
        }
    }
}
