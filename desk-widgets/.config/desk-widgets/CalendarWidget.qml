import QtQuick
import Quickshell
import Quickshell.Io

// Agenda card: upcoming Google Calendar events (secret iCal URL in secrets/ical-url),
// refreshed every 10 minutes and on click of the refresh icon.
DeskWindow {
    id: root
    contentWidth: 460
    contentHeight: 520

    property int maxItems: 4
    // card height follows the number of events shown (header + rows), see shell.qml
    readonly property int shownCount: Math.max(1, Math.min(maxItems, events.length))
    readonly property int naturalHeight: Theme.pad * 2 + 44 + shownCount * 76 + (shownCount - 1) * 12
    property var events: []
    property string status: "loading"

    readonly property string script: Quickshell.env("HOME") + "/.config/desk-widgets/scripts/calendar.py"
    readonly property string python: Quickshell.env("HOME") + "/.local/share/desk-widgets/venv/bin/python"

    Process {
        id: fetch
        command: [root.python, "-I", root.script]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.status = d.status;
                    root.events = d.events;
                } catch (e) {
                    root.status = "error";
                }
            }
        }
    }
    Timer {
        interval: 10 * 60 * 1000
        running: true
        repeat: true
        onTriggered: fetch.running = true
    }
    // re-render "Dnes/Zajtra" labels after midnight
    SystemClock { id: clock; precision: SystemClock.Minutes }

    function dayLabel(iso) {
        const d = new Date(iso);
        const today = new Date(clock.date); today.setHours(0, 0, 0, 0);
        const day = new Date(d); day.setHours(0, 0, 0, 0);
        const diff = Math.round((day - today) / 86400000);
        if (diff <= 0) return "Dnes";
        if (diff === 1) return "Zajtra";
        const s = d.toLocaleDateString(Qt.locale("sk_SK"), "ddd d. M.");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    Card {
        anchors.fill: parent

        Row {
            id: header
            x: Theme.pad
            y: Theme.pad - 4
            spacing: 10
            Icon { name: "calendar_month"; color: Theme.primary; size: 24 }
            Text {
                text: "Kalendár"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 20
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
            Icon {
                name: fetch.running ? "sync" : (root.status === "offline" ? "cloud_off" : "refresh")
                size: 18
                opacity: refresh.containsMouse || fetch.running || root.status === "offline" ? 1 : 0.45
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    id: refresh
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!fetch.running) fetch.running = true
                }
            }
        }

        Text {
            visible: root.events.length === 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.pad
            anchors.top: header.bottom
            anchors.topMargin: 22
            wrapMode: Text.Wrap
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: 17
            text: ({
                "no-url": "Vlož tajnú iCal adresu do ~/.config/desk-widgets/secrets/ical-url",
                "error": "Kalendár sa nepodarilo načítať",
                "loading": "Načítavam…",
            })[root.status] ?? "Žiadne udalosti na najbližšie 2 mesiace"
        }

        Column {
            id: list
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.margins: Theme.pad
            anchors.topMargin: 18
            spacing: 12

            Repeater {
                model: root.events.slice(0, root.maxItems)
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool today: root.dayLabel(modelData.start) === "Dnes"
                    width: list.width
                    height: 76
                    radius: 16
                    color: today ? Qt.alpha(Theme.primaryContainer, 0.75) : Theme.track

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 3
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.dayLabel(modelData.start) + "  ·  " + (modelData.allDay ? "celý deň" : Qt.formatTime(new Date(modelData.start), "HH:mm"))
                                + (modelData.location !== "" ? "  ·  " + modelData.location : "")
                            color: Theme.primary
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                        Text {
                            width: parent.width
                            text: modelData.title
                            elide: Text.ElideRight
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 17
                        }
                    }
                }
            }
        }
    }
}
