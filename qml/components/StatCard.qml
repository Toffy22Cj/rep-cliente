import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

// Tarjeta de indicador (KPI): icono, valor y descripción.
Card {
    id: root
    property string title: "Title"
    property string value: "0"
    property string icon: "📊"
    property color color: Theme.primary
    property color iconBackground: Qt.rgba(color.r, color.g, color.b, 0.12)

    Layout.fillWidth: true
    Layout.preferredHeight: 112
    padding: Theme.spacingM + Theme.spacingXs

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacingM

        Rectangle {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52
            radius: Theme.radiusM
            color: root.iconBackground
            Label {
                anchors.centerIn: parent
                text: root.icon
                font.pixelSize: 24
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label {
                text: root.value
                font.pixelSize: Theme.fontHeadline
                font.weight: Font.Bold
                color: Theme.textPrimary
            }
            Label {
                text: root.title
                font.pixelSize: Theme.fontBody
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
