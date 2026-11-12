import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

// Mensaje centrado para listas vacías.
ColumnLayout {
    property string icon: "📭"
    property string title: qsTr("Sin datos")
    property string message: ""
    spacing: Theme.spacingS

    Label {
        text: parent.icon
        font.pixelSize: 40
        Layout.alignment: Qt.AlignHCenter
    }
    Label {
        text: parent.title
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSubtitle
        font.weight: Font.DemiBold
        Layout.alignment: Qt.AlignHCenter
    }
    Label {
        visible: parent.message !== ""
        text: parent.message
        color: Theme.textSecondary
        font.pixelSize: Theme.fontBody
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 360
    }
}
