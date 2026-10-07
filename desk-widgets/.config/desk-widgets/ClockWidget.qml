import QtQuick
import Quickshell

// Clock card: big time on the left, Slovak date + week number on the right (scales with width).
DeskWindow {
    id: root
    readonly property real k: Math.min(1, contentWidth / 944)
    contentWidth: 944
    contentHeight: 200

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function weekNumber(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
    }

    Card {
        anchors.fill: parent

        Text {
            id: time
            anchors.left: parent.left
            anchors.leftMargin: Theme.pad + 10
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Math.round(128 * root.k)
            font.weight: Font.Light
            font.letterSpacing: -3
        }

        Rectangle {
            id: divider
            anchors.left: time.right
            anchors.leftMargin: Math.round(36 * root.k)
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height - 70
            radius: 1
            color: Theme.cardBorder
        }

        Column {
            anchors.left: divider.right
            anchors.leftMargin: Math.round(36 * root.k)
            anchors.right: parent.right
            anchors.rightMargin: Theme.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                text: {
                    const s = clock.date.toLocaleDateString(Qt.locale("sk_SK"), "dddd");
                    return s.charAt(0).toUpperCase() + s.slice(1);
                }
                color: Theme.primary
                font.family: Theme.font
                font.pixelSize: Math.round(40 * root.k)
                font.weight: Font.Medium
            }
            Text {
                text: clock.date.toLocaleDateString(Qt.locale("sk_SK"), "d. MMMM yyyy")
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Math.round(26 * root.k)
            }
            Text {
                text: root.weekNumber(clock.date) + ". týždeň"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Math.round(18 * root.k)
            }
        }
    }
}
