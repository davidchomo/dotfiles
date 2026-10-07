// Desktop widgets on the first external monitor (or the one chosen in the settings app /
// $DESK_WIDGETS_SCREEN), run with: qs -p ~/.config/desk-widgets
// Settings app: qs -p ~/.config/desk-widgets/settings.qml (RiceSettings.qml, ~/.config/rice/settings.json)
// Kept outside ~/.config/quickshell because end-4's installer rsyncs that dir with --delete.
//
// Layout: two columns on the screen edges (swappable), the middle stays free.
//   column A : clock / calendar (height = its events) / photos (fill the rest)
//   column B : spotify / system
// Disabled widgets are hidden and the ones below them move up.
import QtQuick
import Quickshell

ShellRoot {
    id: g

    readonly property var w: RiceSettings.widgets
    readonly property bool mirrored: w.mirrored
    readonly property int margin: 72                    // distance from screen edges
    readonly property int gap: 24
    readonly property int colAW: 560
    readonly property int colBW: 460
    readonly property int row1: 200
    readonly property int row2: 520
    readonly property int barH: 63
    readonly property int screenH: Theme.screen ? Theme.screen.height : 1440
    readonly property int top: barH + margin - 16

    // column A
    readonly property int aClockY: top
    readonly property int aCalY: aClockY + (w.clock ? row1 + gap : 0)
    readonly property int aPhotoY: aCalY + (w.calendar ? cal.naturalHeight + gap : 0)
    // column B
    readonly property int bSpotifyY: top
    readonly property int bSystemY: bSpotifyY + (w.spotify ? row1 + gap : 0)

    ClockWidget {
        shown: g.w.clock
        contentWidth: g.colAW
        contentHeight: g.row1
        anchors { top: true; left: !g.mirrored; right: g.mirrored }
        margins { top: g.aClockY; left: g.margin; right: g.margin }
    }
    CalendarWidget {
        id: cal
        shown: g.w.calendar
        contentWidth: g.colAW
        contentHeight: cal.naturalHeight
        anchors { top: true; left: !g.mirrored; right: g.mirrored }
        margins { top: g.aCalY; left: g.margin; right: g.margin }
    }
    PhotoWidget {
        shown: g.w.photos
        contentWidth: g.colAW
        contentHeight: Math.max(200, g.screenH - g.margin - g.aPhotoY)
        anchors { top: true; left: !g.mirrored; right: g.mirrored }
        margins { top: g.aPhotoY; left: g.margin; right: g.margin }
    }

    SpotifyWidget {
        shown: g.w.spotify
        contentWidth: g.colBW
        contentHeight: g.row1
        anchors { top: true; right: !g.mirrored; left: g.mirrored }
        margins { top: g.bSpotifyY; left: g.margin; right: g.margin }
    }
    SystemWidget {
        shown: g.w.system
        contentWidth: g.colBW
        contentHeight: g.row2
        anchors { top: true; right: !g.mirrored; left: g.mirrored }
        margins { top: g.bSystemY; left: g.margin; right: g.margin }
    }
}
