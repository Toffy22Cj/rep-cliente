import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    background: Rectangle { color: Theme.background }

    // ------------------------------------------------ modo evaluación
    // El reloj se ancla a la primera apertura (guardada en disco): cerrar y volver a
    // abrir no reinicia el tiempo. Al llegar a cero se envía solo (o se encola sin red).
    readonly property double limite: estudianteViewModel.limiteEpochMs
    property double ahora: Date.now()
    readonly property int restanteSeg: limite > 0 ? Math.max(0, Math.floor((limite - ahora) / 1000)) : -1
    property bool enviada: false
    property bool pantallaCompleta: false

    function formatoTiempo(seg) {
        const h = Math.floor(seg / 3600), m = Math.floor((seg % 3600) / 60), s = seg % 60
        return (h > 0 ? h + ":" + String(m).padStart(2, "0") : String(m)) + ":" + String(s).padStart(2, "0")
    }

    function enviar() {
        if (enviada) return
        enviada = true
        estudianteViewModel.guardarBorrador()
        estudianteViewModel.submitActividad()
    }

    function cambiarPantallaCompleta() {
        const ventana = root.Window.window
        if (!ventana) return
        pantallaCompleta = !pantallaCompleta
        ventana.visibility = pantallaCompleta ? Window.FullScreen : Window.Windowed
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.limite > 0 && !root.enviada
        onTriggered: {
            root.ahora = Date.now()
            if (root.restanteSeg === 0) {
                submissionDialog.close()
                root.enviar()
            }
        }
    }

    Component.onDestruction: {
        // Al salir se guarda el borrador y se restaura la ventana
        if (!enviada) estudianteViewModel.guardarBorrador()
        if (pantallaCompleta && root.Window.window) root.Window.window.visibility = Window.Windowed
    }

    header: PageHeader {
        title: estudianteViewModel.currentActivityTitle
        subtitle: estudianteViewModel.currentActivityDescription
        AppButton {
            text: root.pantallaCompleta ? qsTr("Salir de pantalla completa") : qsTr("⛶ Modo examen")
            variant: "secondary"
            onClicked: root.cambiarPantallaCompleta()
        }
        Rectangle {
            visible: root.restanteSeg >= 0
            implicitWidth: reloj.implicitWidth + 2 * Theme.spacingM
            implicitHeight: 40
            radius: Theme.radiusM
            color: root.restanteSeg < 60 ? Theme.dangerSoft : root.restanteSeg < 300 ? Theme.warningSoft : Theme.primarySoft
            Label {
                id: reloj
                anchors.centerIn: parent
                text: "⏱ " + root.formatoTiempo(Math.max(0, root.restanteSeg))
                font.pixelSize: Theme.fontSubtitle
                font.weight: Font.Bold
                font.family: "monospace"
                color: root.restanteSeg < 60 ? Theme.dangerDark : root.restanteSeg < 300 ? Theme.warning : Theme.primary
                Accessible.name: qsTr("Tiempo restante %1").arg(text)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Rectangle {
            Layout.fillWidth: true
            visible: estudianteViewModel.borradorRecuperado
            implicitHeight: recuperado.implicitHeight + 2 * Theme.spacingS
            radius: Theme.radiusM
            color: Theme.infoSoft
            Label {
                id: recuperado
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                wrapMode: Text.WordWrap
                color: Theme.textPrimary
                text: qsTr("Se recuperaron las respuestas guardadas en este equipo. El tiempo cuenta desde que abrió la actividad por primera vez.")
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

            enabled: !root.enviada
            onClicked: {
                submissionDialog.open()
            }
        }
    }

    Dialog {
        id: submissionDialog
        property int faltan: 0
        onAboutToShow: faltan = estudianteViewModel.preguntaModel.sinResponder()
        title: "Confirmar Envío"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            width: parent.width
            spacing: 10
            Label {
                text: submissionDialog.faltan > 0
                      ? qsTr("Tiene %n pregunta(s) sin responder. ¿Enviar de todas formas?", "", submissionDialog.faltan)
                      : qsTr("¿Está seguro de que desea enviar sus respuestas?")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        onAccepted: root.enviar()
    }

    Connections {
        target: estudianteViewModel
        function onErrorOccurred(error) { root.enviada = false }
        function onActivitySubmitted(success, message) {
            if (!success) root.enviada = false
            resultDialog.exito = success
            resultDialog.messageText = (root.limite > 0 && root.restanteSeg === 0 ? qsTr("Se acabó el tiempo y la actividad se envió automáticamente.") + "\n\n" : "") + message;
            resultDialog.open();
        }
    }

    Dialog {
        id: resultDialog
        property string messageText: ""
        property bool exito: true
        title: exito ? "✔ " + qsTr("¡Hecho!") : qsTr("Resultado")
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
