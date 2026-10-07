import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Rotating photos from ~/Pictures/Desk (pulled from the Pixel via KDE Connect, scripts/pixel-sync.sh).
// Click = next photo, ↻ button = sync now.
DeskWindow {
    id: root
    contentWidth: 480
    contentHeight: 600

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Desk"
    property int interval: Math.max(5, RiceSettings.widgets.photoInterval) * 1000
    property bool showingA: true

    FolderListModel {
        id: photos
        folder: "file://" + root.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.JPG", "*.JPEG", "*.png", "*.PNG", "*.webp"]
        showDirs: false
        sortField: FolderListModel.Name
        onStatusChanged: if (status === FolderListModel.Ready && imgA.source == "") root.next()
    }

    function next() {
        if (photos.count === 0) return;
        let i = Math.floor(Math.random() * photos.count);
        const current = (showingA ? imgA : imgB).source.toString();
        if (photos.count > 1 && photos.get(i, "fileUrl").toString() === current)
            i = (i + 1) % photos.count;
        (showingA ? imgB : imgA).source = photos.get(i, "fileUrl");
        // the incoming image fades in once loaded (see onStatusChanged below)
    }

    Timer {
        interval: root.interval
        running: photos.count > 1
        repeat: true
        onTriggered: root.next()
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.card
        border.width: 1
        border.color: Theme.cardBorder

        Image {
            id: imgA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            autoTransform: true
            sourceSize: Qt.size(root.width * 2, root.height * 2)
            opacity: root.showingA ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
            onStatusChanged: if (status === Image.Ready && !root.showingA) root.showingA = true
        }
        Image {
            id: imgB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            autoTransform: true
            sourceSize: Qt.size(root.width * 2, root.height * 2)
            opacity: root.showingA ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
            onStatusChanged: if (status === Image.Ready && root.showingA) root.showingA = false
        }

        Column {
            visible: photos.count === 0
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 12
            Icon { name: "photo_library"; size: 48; color: Theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: "Daj fotky do Pictures/Desk v Pixeli\na klikni na ↻ vpravo hore"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 16
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: photos.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.next()
        }

        // "Sync from Pixel" button (KDE Connect, scripts/pixel-sync.sh)
        Rectangle {
            id: syncBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 14
            width: 42
            height: 42
            radius: 21
            color: syncHover.containsMouse ? Theme.primary : Qt.alpha(Theme.c.surface_container_high ?? "#322824", 0.85)
            opacity: syncHover.containsMouse || sync.running || photos.count === 0 ? 1 : 0.55
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Icon {
                id: syncIcon
                anchors.centerIn: parent
                name: "sync"
                size: 24
                color: syncHover.containsMouse ? (Theme.c.on_primary ?? "#2b0f00") : Theme.text
                RotationAnimation on rotation {
                    running: sync.running
                    from: 360; to: 0
                    duration: 1000
                    loops: Animation.Infinite
                    onStopped: syncIcon.rotation = 0
                }
            }
            MouseArea {
                id: syncHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (!sync.running) sync.running = true
            }
        }
    }

    Process {
        id: sync
        command: [Quickshell.env("HOME") + "/.config/desk-widgets/scripts/pixel-sync.sh"]
    }
}
