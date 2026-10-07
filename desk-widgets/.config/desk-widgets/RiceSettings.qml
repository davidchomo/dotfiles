pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared settings for the desktop widgets, the Claude Code bridge and the gaming helpers.
// Stored in ~/.config/rice/settings.json (machine-specific, not in git); written by the
// settings app (qs -p ~/.config/desk-widgets/settings.qml) and read live by everything else.
// Python/shell consumers read the same file with defaults matching the ones below.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/rice/settings.json"
    property alias widgets: adapter.widgets
    property alias claude: adapter.claude
    property alias games: adapter.games
    property bool ready: false

    Timer { id: reloadTimer; interval: 50; onTriggered: file.reload() }
    Timer { id: writeTimer; interval: 50; onTriggered: file.writeAdapter() }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.config/rice"]);
                writeAdapter();
            }
            root.ready = true;
        }

        JsonAdapter {
            id: adapter

            property JsonObject widgets: JsonObject {
                property bool clock: true
                property bool calendar: true
                property bool photos: true
                property bool spotify: true
                property bool system: true
                property string screen: ""        // "" = first external monitor
                property bool mirrored: false     // swap the left/right columns
                property int photoInterval: 25    // seconds
                property int calendarDays: 60
                property int calendarItems: 4
            }

            property JsonObject claude: JsonObject {
                property bool enabled: true
                property string model: ""          // "" = Claude Code default, or fable/opus/sonnet/haiku
                property string permissions: "all" // all | edit | read
                property string language: "sk"     // sk | en
                property string style: "short"     // short | detailed
                property string workdir: "~"
            }

            property JsonObject games: JsonObject {
                property string fpsLimit: "60"     // first MangoHud fps_limit value: 60 | 120 | 144 | 0 (none)
                property bool steamOptions: true   // auto launch options for all games
                property bool boostInGames: false  // gamemode turns CPU boost on while a game runs
            }
        }
    }
}
