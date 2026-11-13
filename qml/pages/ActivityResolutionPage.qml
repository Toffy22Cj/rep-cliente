import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    background: Rectangle { color: Theme.background }

    header: PageHeader {
        title: estudianteViewModel.currentActivityTitle
        subtitle: estudianteViewModel.currentActivityDescription
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Questions List
        ListView {
            id: questionsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: estudianteViewModel.preguntaModel
            spacing: 20
            clip: true

            delegate: Column {
                width: questionsList.width - 40
                x: 20
                spacing: 15

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                Label {
                    text: (index + 1) + ". " + enunciado
                    font.pixelSize: 18
                    font.bold: true
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Imagen o archivo adjunto de la pregunta
                Adjunto {
                    width: parent.width
                    visible: archivoDisponible
                    url: archivoDisponible ? archivoUrl : ""
                    nombre: nombreArchivo
                    esImagen: archivoEsImagen
                }

                // Multiple Choice / True-False
                Column {
                    id: optionsColumn
                    property int questionIndex: index // Capture the outer index
                    visible: tipo !== "RESPUESTA_ABIERTA"
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: opciones
                        delegate: Column {
                            required property var modelData
                            width: optionsColumn.width
                            spacing: 4
                            RadioButton {
                            text: modelData.texto
                            checked: opcionSeleccionadaId === modelData.id
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: parent.indicator.width + parent.spacing
                                wrapMode: Text.WordWrap
                                width: questionsList.width - 100
                            }
                            onClicked: {
                                estudianteViewModel.preguntaModel.selectOpcion(optionsColumn.questionIndex, modelData.id)
                            }
                            }
                            Adjunto {
                                x: 40
                                width: parent.width - 40
                                visible: modelData.archivoDisponible === true
                                url: modelData.archivoDisponible ? modelData.archivoUrl : ""
                                nombre: modelData.nombreArchivo || ""
                                esImagen: /\.(png|jpe?g|gif|webp)$/i.test(modelData.nombreArchivo || "")
                                alturaMaxima: 180
                            }
                        }
                    }
                }

                // Open Ended
                TextArea {
                    property int questionIndex: index
                    visible: tipo === "RESPUESTA_ABIERTA"
                    placeholderText: "Escribe tu respuesta aquí..."
                    width: parent.width
                    height: 100
                    text: respuestaAbierta
                    wrapMode: TextArea.Wrap
                    onTextChanged: {
                        if (activeFocus) {
                            estudianteViewModel.preguntaModel.setRespuestaAbierta(questionIndex, text)
                        }
                    }
                    background: Rectangle {
                        border.color: Theme.border
                        radius: 5
                    }
                }
            }
        }

        // Footer
        Button {
            text: "Finalizar y Enviar"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 200
            Layout.preferredHeight: 50
            
            background: Rectangle {
                color: Theme.success
                radius: 25
            }
            
            contentItem: Label {
                text: parent.text
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                submissionDialog.open()
            }
        }
    }

    Dialog {
        id: submissionDialog
        title: "Confirmar Envío"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            width: parent.width
            spacing: 10
            Label {
                text: "¿Estás seguro de que deseas enviar tus respuestas?"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        onAccepted: {
            estudianteViewModel.submitActividad()
        }
    }

    Connections {
        target: estudianteViewModel
        function onActivitySubmitted(success, message) {
            resultDialog.messageText = message;
            resultDialog.open();
        }
    }

    Dialog {
        id: resultDialog
        property string messageText: ""
        title: "Resultado"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok

        ColumnLayout {
            width: parent.width
            spacing: 10
            Label {
                text: resultDialog.messageText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        onAccepted: {
            stackView.pop();
        }
    }
}
