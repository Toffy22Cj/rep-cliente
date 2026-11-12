import QtQuick
import QtQuick.Controls
import Rep

// Pestaña con indicador inferior en el color de marca.
TabButton {
    id: control
    font.pixelSize: Theme.fontBody
    font.weight: checked ? Font.DemiBold : Font.Normal
    implicitHeight: Theme.controlHeight

    contentItem: Label {
        text: control.text
        font: control.font
        color: control.checked ? Theme.primary : Theme.textSecondary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: control.hovered && !control.checked ? Theme.surfaceAlt : Theme.surface
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: control.checked ? 3 : 1
            color: control.checked ? Theme.primary : Theme.border
        }
    }
}
