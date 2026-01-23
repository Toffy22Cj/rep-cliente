import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    title: "Editor de Preguntas"
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
                text: "Preguntas de la Actividad"
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
            text: "Agregar Nueva Pregunta"
            font.bold: true
            font.pixelSize: 16
        }

        Rectangle {
            Layout.fillWidth: true
            height: 250
            color: "#f8f9fa"
            radius: 8
            border.color: "#dee2e6"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                
                TextField {
                    id: enunciadoField
                    placeholderText: "Enunciado de la pregunta"
                    Layout.fillWidth: true
                }

                ComboBox {
                    id: tipoPreguntaCombo
                    model: ["OPCION_MULTIPLE", "VERDADERO_FALSO", "RESPUESTA_ABIERTA"]
                    Layout.fillWidth: true
                }

                Label { text: "Opciones (marcar la correcta):"; font.pixelSize: 12 }

                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: op1; placeholderText: "Opción 1"; Layout.fillWidth: true }
                    CheckBox { id: op1Correct }
                }

                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: op2; placeholderText: "Opción 2"; Layout.fillWidth: true }
                    CheckBox { id: op2Correct }
                }

                Button {
                    text: "Guardar Pregunta"
                    Layout.fillWidth: true
                    highlighted: true
                    onClicked: {
                        let options = []
                        if (op1.text !== "") options.push({texto: op1.text, esCorrecta: op1Correct.checked})
                        if (op2.text !== "") options.push({texto: op2.text, esCorrecta: op2Correct.checked})
                        
                        profesorViewModel.addPregunta(
                            actividadId,
                            enunciadoField.text,
                            tipoPreguntaCombo.currentText,
                            options
                        )
                    }
                }
            }
        }

        Label {
            text: "Preguntas Guardadas"
            font.bold: true
            font.pixelSize: 16
            Layout.topMargin: 10
        }

        // Simplified list for demo; in real app we'd fetch and use a model
        ListView {
            id: preguntasList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: 0 // Placeholder
            delegate: ItemDelegate {
                width: parent.width
                text: modelData.enunciado
            }
        }
    }

    Connections {
        target: profesorViewModel
        function onPreguntaCreada(id) {
            console.log("Pregunta creada con ID: " + id)
            enunciadoField.text = ""
            op1.text = ""
            op2.text = ""
            op1Correct.checked = false
            op2Correct.checked = false
        }
    }
}
