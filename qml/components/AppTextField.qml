import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

// Campo de texto con etiqueta superior y mensaje de error opcional.
ColumnLayout {
    id: root
    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property alias echoMode: field.echoMode
    property alias field: field
    property string label: ""
    property string errorText: ""

    signal accepted()
    spacing: Theme.spacingXs

    Label {
        visible: root.label !== ""
        text: root.label
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
        font.weight: Font.Medium
    }

    TextField {
        id: field
        Layout.fillWidth: true
        implicitHeight: Theme.controlHeight
        leftPadding: Theme.spacingM
        rightPadding: Theme.spacingM
        font.pixelSize: Theme.fontBody
        color: Theme.textPrimary
        placeholderTextColor: Theme.textMuted
        selectByMouse: true
        Accessible.name: root.label !== "" ? root.label : placeholderText
        onAccepted: root.accepted()
        background: Rectangle {
            radius: Theme.radiusM
            color: Theme.surface
            border.width: field.activeFocus ? 2 : 1
            border.color: root.errorText !== "" ? Theme.danger
                        : field.activeFocus ? Theme.primary : Theme.border
        }
    }

    Label {
        visible: root.errorText !== ""
        text: root.errorText
        color: Theme.danger
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
