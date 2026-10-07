// Desktop widgets on the first external monitor (or $DESK_WIDGETS_SCREEN), run with: qs -p ~/.config/desk-widgets
// Kept outside ~/.config/quickshell because end-4's installer rsyncs that dir with --delete.
//
// Layout: two columns on the screen edges, rows of equal height in both, middle stays free.
//   left  : clock / calendar (height = its events) / photos (fill the rest)
//   right : spotify / system
import QtQuick
import Quickshell

ShellRoot {
    id: g

    readonly property int margin: 72                    // distance from screen edges
    readonly property int gap: 24
    readonly property int leftW: 560
    readonly property int rightW: 460
    readonly property int row1: 200
    readonly property int row2: 520
    readonly property int barH: 63
    readonly property int screenH: Theme.screen ? Theme.screen.height : 1440
    readonly property int y1: barH + margin - 16
    readonly property int y2: y1 + row1 + gap
    readonly property int y3: y2 + cal.naturalHeight + gap
    readonly property int row3: screenH - margin - y3   // photos fill the rest of the column

    // left column
    ClockWidget {
        contentWidth: g.leftW
        contentHeight: g.row1
        anchors { top: true; left: true }
        margins { top: g.y1; left: g.margin }
    }
    CalendarWidget {
        id: cal
        contentWidth: g.leftW
        contentHeight: cal.naturalHeight
        anchors { top: true; left: true }
        margins { top: g.y2; left: g.margin }
    }
    PhotoWidget {
        contentWidth: g.leftW
        contentHeight: g.row3
        anchors { top: true; left: true }
        margins { top: g.y3; left: g.margin }
    }

    // right column
    SpotifyWidget {
        contentWidth: g.rightW
        contentHeight: g.row1
        anchors { top: true; right: true }
        margins { top: g.y1; right: g.margin }
    }
    SystemWidget {
        contentWidth: g.rightW
        contentHeight: g.row2
        anchors { top: true; right: true }
        margins { top: g.y2; right: g.margin }
    }
}
