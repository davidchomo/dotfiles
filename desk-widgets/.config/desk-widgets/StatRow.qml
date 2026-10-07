import QtQuick

// icon | label ............ value   + thin bar (fraction 0..1, hidden when < 0)
Column {
    id: row
    property string icon
    property string label
    property string value
    property real fraction: -1
    property bool hot: false

    spacing: 6

    Item {
        width: row.width
        height: 26
        Icon {
            id: ic
            name: row.icon
            size: 22
            color: row.hot ? Theme.warn : Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: row.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 16
            anchors.left: ic.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: row.value
            color: row.hot ? Theme.warn : Theme.subtext
            font.family: Theme.mono
            font.pixelSize: 15
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Rectangle {
        visible: row.fraction >= 0
        width: row.width
        height: 5
        radius: 3
        color: Theme.track
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, row.fraction))
            height: parent.height
            radius: 3
            color: row.hot ? Theme.warn : Theme.primary
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }
    }
}
