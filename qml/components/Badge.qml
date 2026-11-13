import QtQuick
import QtQuick.Controls
import Rep

// Etiqueta compacta de estado.
Rectangle {
    id: badge
    property string text: ""
    property color tint: Theme.primary
    property color softTint: Theme.primarySoft

    implicitWidth: label.implicitWidth + Theme.spacingM
    implicitHeight: label.implicitHeight + Theme.spacingXs * 2
    radius: height / 2
    color: softTint

    Label {
        id: label
        anchors.centerIn: parent
        text: badge.text
        color: badge.tint
        font.pixelSize: Theme.fontCaption
        font.weight: Font.DemiBold
    }
}
