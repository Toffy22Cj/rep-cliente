import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            Label {
                text: "Dashboard Profesor"
                color: "white"
                font.bold: true
                Layout.leftMargin: 10
            }
            Item { Layout.fillWidth: true }
            Label {
                text: sessionManager.userName
                color: "white"
                Layout.rightMargin: 10
            }
            ToolButton {
                text: "Log Out"
                onClicked: sessionManager.clear()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Statistics Cards
        RowLayout {
            spacing: 20
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true
                height: 100
                color: "#3498db"
                radius: 10
                Column {
                    anchors.centerIn: parent
                    Label { text: "Estudiantes"; color: "white"; font.bold: true }
                    Label { text: profesorViewModel.totalEstudiantes; color: "white"; font.pixelSize: 24 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 100
                color: "#2ecc71"
                radius: 10
                Column {
                    anchors.centerIn: parent
                    Label { text: "Actividades Activas"; color: "white"; font.bold: true }
                    Label { text: profesorViewModel.actividadesActivas; color: "white"; font.pixelSize: 24 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 100
                color: "#e67e22"
                radius: 10
                Column {
                    anchors.centerIn: parent
                    Label { text: "Tareas por Calificar"; color: "white"; font.bold: true }
                    Label { text: profesorViewModel.entregasPendientes; color: "white"; font.pixelSize: 24 }
                }
            }
        }

        Label {
            text: "Mis Actividades"
            font.pixelSize: 20
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: profesorViewModel.actividadModel
            spacing: 10
            clip: true

            delegate: ItemDelegate {
                width: parent.width
                height: 80
                background: Rectangle {
                    color: "white"
                    border.color: "#bdc3c7"
                    radius: 5
                }

                contentItem: RowLayout {
                    spacing: 20
                    Column {
                        Layout.fillWidth: true
                        Label { text: model.titulo; font.bold: true; font.pixelSize: 16 }
                        Label { text: "Tipo: " + model.tipo; color: "#7f8c8d" }
                    }
                    Button {
                        text: "Ver Resultados"
                        onClicked: console.log("Ver resultados de " + model.id)
                    }
                    Button {
                        text: "Editar"
                        onClicked: console.log("Editar actividad " + model.id)
                    }
                }
            }
        }

        Button {
            text: "+ Crear Nueva Actividad"
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            onClicked: console.log("Crear actividad")
        }
    }

    Component.onCompleted: {
        profesorViewModel.loadDashboard();
    }
}
