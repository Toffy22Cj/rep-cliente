import QtQuick
import QtQuick.Controls
import Rep

// Círculo con iniciales.
Rectangle {
    id: avatar
    property string text: "?"
    property int size: 40
    property color tint: Theme.primary

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: tint

    Label {
        anchors.centerIn: parent
        text: avatar.text
        color: Theme.textOnPrimary
        font.pixelSize: Math.round(avatar.size * 0.4)
        font.weight: Font.DemiBold
    }
}
