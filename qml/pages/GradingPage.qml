import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    title: "Calificar Entregas"
    property var actividadId: 0

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "\u2190"
                onClicked: stackView.pop()
            }
            Label {
                text: "Calificar Entregas"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: "Estudiantes que han entregado"
            font.bold: true
            font.pixelSize: 16
        }

        ListView {
            id: submissionsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: 0 // In real app, we'd fetch responses
            spacing: 10
            clip: true

            delegate: ItemDelegate {
                width: submissionsList.width
                height: 70
                background: Rectangle {
                    color: "white"
                    border.color: "#ecf0f1"
                    radius: 8
                }

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    Column {
                        Layout.fillWidth: true
                        Label { text: modelData.nombreEstudiante; font.bold: true }
                        Label { text: "Entregado: " + modelData.fechaEntrega; color: "#7f8c8d"; font.pixelSize: 12 }
                    }
                    Label {
                        text: modelData.calificada ? modelData.nota : "Pendiente"
                        color: modelData.calificada ? "#27ae60" : "#e67e22"
                        font.bold: true
                    }
                    Button {
                        text: "Ver/Calificar"
                        onClicked: console.log("Calificar a " + modelData.estudianteId)
                    }
                }
            }
        }
    }
}
