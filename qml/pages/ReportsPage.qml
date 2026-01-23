import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    title: "Reportes"

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "\u2190"
                onClicked: stackView.pop()
            }
            Label {
                text: "Reportes"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        
        Label {
            text: "🚧"
            font.pixelSize: 48
            Layout.alignment: Qt.AlignHCenter
        }
        
        Label {
            text: "Sección de Reportes en Construcción"
            font.pixelSize: 18
            color: "#7f8c8d"
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
