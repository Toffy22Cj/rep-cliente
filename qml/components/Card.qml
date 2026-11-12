import QtQuick
import QtQuick.Controls
import Rep

// Contenedor de superficie con borde y radio estándar.
Pane {
    id: card
    property bool hoverable: false
    property alias radius: bg.radius
    property color tint: Theme.surface
    hoverEnabled: hoverable
    padding: Theme.spacingL

    background: Rectangle {
        id: bg
        radius: Theme.radiusL
        color: card.tint
        border.color: card.hoverable && card.hovered ? Theme.borderStrong : Theme.border
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }
}
