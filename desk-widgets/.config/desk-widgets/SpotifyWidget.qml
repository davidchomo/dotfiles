import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets

// Now playing in Spotify (MPRIS). Click on the card = focus/launch Spotify; buttons control playback.
DeskWindow {
    id: root
    contentWidth: 480
    contentHeight: 168

    readonly property MprisPlayer player: {
        for (const p of Mpris.players.values)
            if (p.identity.toLowerCase() === "spotify" || p.desktopEntry === "spotify") return p;
        return null;
    }
    // cover art is cached locally by scripts/fetch-art.sh (never load https:// in Quickshell)
    readonly property string artUrl: player?.trackArtUrl ?? ""
    property string artFile: ""
    property string fetchingUrl: ""
    function updateArt() {
        if (artUrl.startsWith("file://")) { artFile = artUrl; return; }
        if (!artUrl.startsWith("http")) { artFile = ""; return; }
        if (artFetch.running) return;            // artDebounce retries after it finishes
        fetchingUrl = artUrl;
        artFetch.running = true;
    }
    onArtUrlChanged: artDebounce.restart()
    Component.onCompleted: artDebounce.restart()
    Timer { id: artDebounce; interval: 300; onTriggered: root.updateArt() }
    Process {
        id: artFetch
        command: [Quickshell.env("HOME") + "/.config/desk-widgets/scripts/fetch-art.sh", root.fetchingUrl]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.artFile = "file://" + text.trim()
        }
        // track changed while downloading -> fetch the new one
        onRunningChanged: if (!running && root.fetchingUrl !== root.artUrl) artDebounce.restart()
    }

    readonly property string openScript: Quickshell.env("HOME") + "/.config/desk-widgets/scripts/spotify-open.sh"

    // MPRIS position is not pushed; poll it while playing
    Timer {
        interval: 1000
        repeat: true
        running: root.player !== null && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    function fmt(sec) {
        if (!sec || sec < 0) return "0:00";
        const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    Card {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached([root.openScript])
        }

        ClippingRectangle {
            id: art
            width: parent.height - Theme.pad * 2
            height: width
            radius: 18
            anchors.left: parent.left
            anchors.leftMargin: Theme.pad
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.primaryContainer

            Image {
                anchors.fill: parent
                source: root.artFile
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(art.width * 2, art.height * 2)
                visible: status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                visible: root.artFile === ""
                name: "music_note"
                size: 52
                color: Theme.onPrimaryContainer
            }
        }

        Column {
            anchors.left: art.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: Theme.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Row {
                spacing: 6
                Icon { name: "graphic_eq"; size: 16; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: !root.player ? "Spotify" : root.player.isPlaying ? "Práve hrá" : "Pozastavené"
                    color: Theme.primary
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }
            Text {
                width: parent.width
                text: root.player?.trackTitle || "Nič nehrá"
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                text: root.player ? (root.player.trackArtist || "") : "Klikni pre otvorenie Spotify"
                elide: Text.ElideRight
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 15
            }

            // progress
            Item {
                width: parent.width
                height: 22
                visible: root.player !== null && root.player.lengthSupported && root.player.length > 0
                Rectangle {
                    id: bar
                    anchors.left: parent.left
                    anchors.right: time.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 2
                    color: Theme.track
                    Rectangle {
                        height: parent.height
                        radius: 2
                        color: Theme.primary
                        width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                    }
                }
                Text {
                    id: time
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.player ? root.fmt(root.player.position) + " / " + root.fmt(root.player.length) : ""
                    color: Theme.subtext
                    font.family: Theme.mono
                    font.pixelSize: 12
                }
            }

            // controls
            Row {
                spacing: 8
                visible: root.player !== null
                Repeater {
                    model: [
                        { icon: "skip_previous", act: () => root.player.previous(), ok: () => root.player.canGoPrevious },
                        { icon: root.player?.isPlaying ? "pause" : "play_arrow", act: () => root.player.togglePlaying(), ok: () => root.player.canTogglePlaying },
                        { icon: "skip_next", act: () => root.player.next(), ok: () => root.player.canGoNext },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: index === 1 ? 44 : 36
                        height: width
                        radius: width / 2
                        color: index === 1 ? Theme.primary : (hover.containsMouse ? Theme.track : "transparent")
                        opacity: root.player && modelData.ok() ? 1 : 0.4
                        anchors.verticalCenter: parent.verticalCenter
                        Icon {
                            anchors.centerIn: parent
                            name: parent.modelData.icon
                            size: parent.index === 1 ? 28 : 24
                            color: parent.index === 1 ? (Theme.c.on_primary ?? "#2b0f00") : Theme.text
                        }
                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.player && parent.modelData.ok()) parent.modelData.act()
                        }
                    }
                }
            }
        }
    }
}
