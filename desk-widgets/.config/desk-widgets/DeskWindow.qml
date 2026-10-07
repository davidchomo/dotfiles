import QtQuick
import Quickshell
import Quickshell.Wayland

// One layer-shell surface per widget, on the Bottom layer (under windows, above end-4's wallpaper
// thanks to the layer_rule "order" in ~/.config/hypr/custom/rules.lua). Each widget gets its own
// surface so that clicks only land on the widget itself.
PanelWindow {
    id: win

    default property alias content: holder.data
    property int contentWidth: 400
    property int contentHeight: 200
    property bool shown: true        // from RiceSettings (settings app)

    screen: Theme.screen
    visible: Theme.screen !== null && shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "desk-widgets"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Item {
        id: holder
        anchors.fill: parent
    }
}
