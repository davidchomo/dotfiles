import QtQuick

// Frosted card: translucent surface (Hyprland blurs the layer behind it), thin outline.
Rectangle {
    color: Theme.card
    radius: Theme.radius
    border.width: 1
    border.color: Theme.cardBorder
}
