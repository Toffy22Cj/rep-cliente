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
                text: "Dashboard Estudiante"
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
        anchors.margins: 10
        spacing: 20

        Label {
            text: "Mis Materias"
            font.pointSize: 18
            font.bold: true
        }

        ListView {
            id: materiasList
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            orientation: ListView.Horizontal
            model: estudianteViewModel.materiaModel
            spacing: 10
            clip: true

            delegate: ItemDelegate {
                width: 150
                height: 100
                background: Rectangle {
                    color: "#3498db"
                    radius: 10
                }
                contentItem: Text {
                    text: model.nombre
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                onClicked: estudianteViewModel.loadActividadesByMateria(model.id)
            }
        }

        Label {
            text: "Actividades Pendientes"
            font.pointSize: 18
            font.bold: true
        }

        ListView {
            id: actividadesList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: estudianteViewModel.actividadModel
            spacing: 10
            clip: true

            delegate: ItemDelegate {
                width: parent.width
                height: 100
                padding: 10
                background: Rectangle {
                    color: "white"
                    border.color: "#bdc3c7"
                    radius: 5
                }
                contentItem: RowLayout {
                    spacing: 10
                    Column {
                        Layout.fillWidth: true
                        Text { text: model.titulo; font.bold: true; font.pointSize: 14 }
                        Text { text: model.materiaNombre; color: "#7f8c8d" }
                        Text { text: "Entrega: " + model.fechaEntrega; color: "#e74c3c" }
                    }
                    Column {
                        Layout.preferredWidth: 80
                        Label {
                            text: model.tipo
                            font.pixelSize: 12
                            color: "#7f8c8d"
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }
                        Button {
                            text: "Resolver"
                            onClicked: {
                                estudianteViewModel.startActividad(model.id)
                            }
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: estudianteViewModel
        
        function onActividadConPreguntasFetched() {
            stackView.push("ActivityResolutionPage.qml")
        }

        function onErrorOccurred(error) {
            errorDialog.text = error
            errorDialog.open()
        }
    }

    Dialog {
        id: errorDialog
        property alias text: errorLabel.text
        title: "Error"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok
        width: Math.min(root.width - 40, 400)

        contentItem: Column {
            spacing: 10
            Label {
                id: errorLabel
                width: parent.width
                wrapMode: Text.WordWrap
            }
        }
    }

    Component.onCompleted: {
        estudianteViewModel.loadMaterias()
        estudianteViewModel.loadActividades()
    }
}
