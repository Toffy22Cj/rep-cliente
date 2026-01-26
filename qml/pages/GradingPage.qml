import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Page {
    id: root
    title: "Calificar Entregas"
    background: Rectangle { color: "#f4f6f9" }

    property var stackView: StackView.view
    property int actividadId: 0
    property string actividadTitulo: "Calificar"

    Component.onCompleted: {
        if (actividadId > 0) {
            reportsViewModel.loadEntregas(actividadId)
        }
    }
    
    Connections {
        target: reportsViewModel
        function onCalificacionCompleted() {
            console.log("Calificación guardada")
            reportsViewModel.loadEntregas(actividadId)
            successDialog.open()
            editDialog.close()
        }
    }

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            spacing: 15
            ToolButton {
                text: "←"
                font.pixelSize: 20
                onClicked: stackView.pop()
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Label {
                text: actividadTitulo
                color: "white"
                font.bold: true
                font.pixelSize: 18
                Layout.fillWidth: true
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: "Listado de Entregas"
            font.bold: true
            font.pixelSize: 18
            color: "#2c3e50"
        }

        ListView {
            id: submissionsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: reportsViewModel.entregasModel
            spacing: 10

            delegate: Rectangle {
                width: submissionsList.width
                height: 80
                color: "white"
                radius: 8
                border.color: "#ecf0f1"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    // Avatar
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: "#3498db"
                        Label {
                            anchors.centerIn: parent
                            text: model.estudiante ? model.estudiante.charAt(0).toUpperCase() : "?"
                            color: "white"
                            font.bold: true
                        }
                    }

                    // Info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { 
                            text: model.estudiante
                            font.bold: true
                            font.pixelSize: 16
                            color: "#2c3e50"
                        }
                        Label { 
                            text: model.fecha !== "---" ? "Entregado: " + model.fecha : "Pendiente"
                            color: model.fecha !== "---" ? "#27ae60" : "#95a5a6"
                            font.pixelSize: 13
                        }
                    }

                    // Grade Badge
                    Rectangle {
                        visible: model.calificada
                        width: 50; height: 30; radius: 15
                        color: model.nota >= 3.0 ? "#27ae60" : "#c0392b"
                        Label {
                            anchors.centerIn: parent
                            text: model.nota.toFixed(1)
                            color: "white"
                            font.bold: true
                        }
                    }

                    // Action Button
                    Button {
                        text: model.calificada ? "Editar" : "Calificar"
                        highlighted: !model.calificada
                        enabled: model.respuestaId > 0 // Only if submitted
                        onClicked: {
                            editDialog.respuestaId = model.respuestaId
                            editDialog.estudianteNombre = model.estudiante
                            editDialog.currentNota = model.calificada ? model.nota : 0.0
                            notaField.text = editDialog.currentNota
                            editDialog.open()
                        }
                    }
                }
            }
        }
    }

    // Edit Grade Dialog
    Dialog {
        id: editDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 300
        modal: true
        focus: true
        title: "Calificar Entrega"
        standardButtons: Dialog.Save | Dialog.Cancel

        property var respuestaId: 0
        property string estudianteNombre: ""
        property double currentNota: 0.0

        ColumnLayout {
            spacing: 20
            width: parent.width

            Label {
                text: "Estudiante: " + editDialog.estudianteNombre
                font.bold: true
            }

            TextField {
                id: notaField
                placeholderText: "Nota (0.0 - 5.0)"
                Layout.fillWidth: true
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 1 }
            }
        }

        onAccepted: {
            var n = parseFloat(notaField.text)
            if (!isNaN(n) && n >= 0 && n <= 5.0) {
                reportsViewModel.calificar(editDialog.respuestaId, n)
            } else {
                console.error("Nota inválida")
            }
        }
    }

    Dialog {
        id: successDialog
        anchors.centerIn: parent
        modal: true
        title: "Éxito"
        Label { text: "Calificación guardada correctamente." }
        standardButtons: Dialog.Ok
    }
}
