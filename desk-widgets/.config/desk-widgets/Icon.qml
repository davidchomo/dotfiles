import QtQuick

// Material Symbols glyph by name, e.g. Icon { name: "thermostat" }
Text {
    property string name
    property real size: 22
    property bool filled: true

    text: name
    color: Theme.subtext
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "opsz": Math.min(48, Math.max(20, size)) })
    renderType: Text.NativeRendering
}
