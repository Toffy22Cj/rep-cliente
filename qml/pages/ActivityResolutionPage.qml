import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Button {
                text: "← Volver"
                onClicked: stackView.pop()
                flat: true
            }

            Label {
                text: estudianteViewModel.currentActivityTitle
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                text: "Tiempo: 10:00" // Hardcoded for now
                font.pixelSize: 18
                color: "#e74c3c"
            }
        }

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
                    color: "#eee"
                }

                Label {
                    text: (index + 1) + ". " + enunciado
                    font.pixelSize: 18
                    font.bold: true
                    wrapMode: Text.WordWrap
                    width: parent.width
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
                        delegate: RadioButton {
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
                        border.color: "#ddd"
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
                color: "#2ecc71"
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
