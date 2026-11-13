import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Rep
import "../components"

/*
 * Editor de preguntas de una actividad.
 *
 * Antes la lista "Preguntas guardadas" era un marcador de posición (model: 0): las
 * preguntas se guardaban pero nunca se mostraban. Ahora se cargan del servidor, se
 * admiten los tres tipos (opción múltiple, verdadero/falso y abierta), adjuntos
 * (imágenes, PDF, documentos, audio, vídeo) y eliminación.
 */
Page {
    id: root
    property var actividadId: 0
    property string actividadTitulo: ""
    property var preguntas: []
    property string error: ""
    property url archivoSeleccionado: ""
    property bool guardando: false

    background: Rectangle { color: Theme.background }

    header: PageHeader {
        title: root.actividadTitulo !== "" ? root.actividadTitulo : qsTr("Preguntas de la actividad")
        subtitle: qsTr("%n pregunta(s)", "", root.preguntas.length)
    }

    ApiRequests { id: requests }

    readonly property var tipos: [
        { valor: "OPCION_MULTIPLE", texto: qsTr("Opción múltiple") },
        { valor: "VERDADERO_FALSO", texto: qsTr("Verdadero / Falso") },
        { valor: "RESPUESTA_ABIERTA", texto: qsTr("Respuesta abierta") }
    ]
    readonly property string tipoActual: tipoCombo.currentIndex >= 0 ? tipos[tipoCombo.currentIndex].valor : "OPCION_MULTIPLE"

    function nombreTipo(valor) {
        for (const t of tipos) if (t.valor === valor) return t.texto
        return valor
    }

    function cargar() {
        requests.get("/preguntas/actividad/" + actividadId,
                     datos => { root.preguntas = datos || [] },
                     mensaje => { root.error = mensaje })
    }

    function limpiarFormulario() {
        enunciadoField.text = ""
        opcionesModel.clear()
        opcionesModel.append({ texto: "", correcta: true })
        opcionesModel.append({ texto: "", correcta: false })
        verdaderoRadio.checked = true
        archivoSeleccionado = ""
    }

    function validar() {
        if (enunciadoField.text.trim() === "") return qsTr("Escriba el enunciado")
        if (tipoActual === "OPCION_MULTIPLE") {
            let correctas = 0
            for (let i = 0; i < opcionesModel.count; i++) {
                if (opcionesModel.get(i).texto.trim() === "") return qsTr("Todas las opciones deben tener texto")
                if (opcionesModel.get(i).correcta) correctas++
            }
            if (opcionesModel.count < 2) return qsTr("Agregue al menos 2 opciones")
            if (correctas !== 1) return qsTr("Marque exactamente una opción correcta")
        }
        return ""
    }

    function guardar() {
        error = validar()
        if (error !== "") return

        let opciones = []
        if (tipoActual === "OPCION_MULTIPLE") {
            for (let i = 0; i < opcionesModel.count; i++)
                opciones.push({ texto: opcionesModel.get(i).texto.trim(), esCorrecta: opcionesModel.get(i).correcta })
        } else if (tipoActual === "VERDADERO_FALSO") {
            opciones = [{ texto: "Verdadero", esCorrecta: verdaderoRadio.checked },
                        { texto: "Falso", esCorrecta: !verdaderoRadio.checked }]
        }

        guardando = true
        requests.post("/preguntas", {
            actividadId: actividadId,
            enunciado: enunciadoField.text.trim(),
            tipo: tipoActual,
            opciones: opciones
        }, creada => {
            if (archivoSeleccionado.toString() !== "") {
                requests.subir("/api/preguntas/" + creada.id + "/archivo", archivoSeleccionado, {},
                               () => { guardando = false; limpiarFormulario(); cargar() },
                               mensaje => { guardando = false; error = qsTr("La pregunta se guardó, pero el adjunto falló: ") + mensaje; cargar() })
            } else {
                guardando = false
                limpiarFormulario()
                cargar()
            }
        }, mensaje => { guardando = false; error = mensaje })
    }

    function eliminar(pregunta) {
        requests.eliminar("/preguntas/" + pregunta.id, () => cargar(), mensaje => { error = mensaje })
    }

    Component.onCompleted: { limpiarFormulario(); cargar() }

    FileDialog {
        id: selectorArchivo
        title: qsTr("Adjuntar imagen o archivo")
        nameFilters: [qsTr("Imágenes (*.png *.jpg *.jpeg *.gif *.webp)"),
                      qsTr("Documentos (*.pdf *.doc *.docx *.xls *.xlsx *.ppt *.pptx *.odt *.txt)"),
                      qsTr("Audio y vídeo (*.mp3 *.wav *.ogg *.mp4 *.webm)"),
                      qsTr("Todos los archivos (*)")]
        onAccepted: root.archivoSeleccionado = selectedFile
    }

    ListModel { id: opcionesModel }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: Math.min(scroll.availableWidth - 2 * Theme.spacingXl, 900)
            x: (scroll.availableWidth - width) / 2
            y: Theme.spacingL
            spacing: Theme.spacingM

            // ---------------------------------------------------- error
            Rectangle {
                Layout.fillWidth: true
                visible: root.error !== ""
                implicitHeight: errorLabel.implicitHeight + 2 * Theme.spacingS
                radius: Theme.radiusM
                color: Theme.dangerSoft
                Label {
                    id: errorLabel
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    text: root.error
                    color: Theme.dangerDark
                    wrapMode: Text.WordWrap
                }
            }

            // ---------------------------------------------------- formulario
            Card {
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingS

                    Label {
                        text: qsTr("Nueva pregunta")
                        font.pixelSize: Theme.fontSubtitle
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }

                    TextArea {
                        id: enunciadoField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        placeholderText: qsTr("Enunciado de la pregunta")
                        wrapMode: TextEdit.Wrap
                        background: Rectangle { radius: Theme.radiusM; color: Theme.surface; border.color: enunciadoField.activeFocus ? Theme.primary : Theme.border }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: qsTr("Tipo:"); color: Theme.textSecondary }
                        ComboBox {
                            id: tipoCombo
                            Layout.fillWidth: true
                            model: root.tipos
                            textRole: "texto"
                        }
                    }

                    // Opción múltiple
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.tipoActual === "OPCION_MULTIPLE"
                        spacing: Theme.spacingXs
                        Label { text: qsTr("Opciones (marque la correcta):"); color: Theme.textSecondary }
                        Repeater {
                            model: opcionesModel
                            delegate: RowLayout {
                                required property int index
                                required property string texto
                                required property bool correcta
                                Layout.fillWidth: true
                                RadioButton {
                                    checked: correcta
                                    onClicked: {
                                        for (let i = 0; i < opcionesModel.count; i++)
                                            opcionesModel.setProperty(i, "correcta", i === index)
                                    }
                                    ToolTip.visible: hovered
                                    ToolTip.text: qsTr("Respuesta correcta")
                                }
                                TextField {
                                    Layout.fillWidth: true
                                    text: texto
                                    placeholderText: qsTr("Opción %1").arg(index + 1)
                                    onTextEdited: opcionesModel.setProperty(index, "texto", text)
                                }
                                ToolButton {
                                    text: "✕"
                                    enabled: opcionesModel.count > 2
                                    onClicked: {
                                        const eraCorrecta = opcionesModel.get(index).correcta
                                        opcionesModel.remove(index)
                                        if (eraCorrecta) opcionesModel.setProperty(0, "correcta", true)
                                    }
                                }
                            }
                        }
                        AppButton {
                            text: qsTr("+ Agregar opción")
                            variant: "ghost"
                            enabled: opcionesModel.count < 5
                            onClicked: opcionesModel.append({ texto: "", correcta: false })
                        }
                    }

                    // Verdadero / falso
                    RowLayout {
                        visible: root.tipoActual === "VERDADERO_FALSO"
                        Label { text: qsTr("Respuesta correcta:"); color: Theme.textSecondary }
                        RadioButton { id: verdaderoRadio; text: qsTr("Verdadero"); checked: true }
                        RadioButton { text: qsTr("Falso") }
                    }

                    Label {
                        visible: root.tipoActual === "RESPUESTA_ABIERTA"
                        text: qsTr("El estudiante escribirá su respuesta; usted la calificará manualmente.")
                        color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // Adjunto
                    RowLayout {
                        Layout.fillWidth: true
                        AppButton {
                            text: qsTr("📎 Adjuntar imagen o archivo")
                            variant: "secondary"
                            onClicked: selectorArchivo.open()
                        }
                        Label {
                            visible: root.archivoSeleccionado.toString() !== ""
                            text: root.archivoSeleccionado.toString().split("/").pop()
                            color: Theme.textPrimary
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                        ToolButton {
                            visible: root.archivoSeleccionado.toString() !== ""
                            text: "✕"
                            onClicked: root.archivoSeleccionado = ""
                        }
                        Item { Layout.fillWidth: root.archivoSeleccionado.toString() === "" }
                    }

                    AppButton {
                        Layout.fillWidth: true
                        text: root.guardando ? qsTr("Guardando…") : qsTr("Guardar pregunta")
                        enabled: !root.guardando
                        onClicked: root.guardar()
                    }
                }
            }

            // ---------------------------------------------------- preguntas guardadas
            Label {
                text: qsTr("Preguntas guardadas")
                font.pixelSize: Theme.fontSubtitle
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                Layout.topMargin: Theme.spacingS
            }

            EmptyState {
                Layout.fillWidth: true
                visible: root.preguntas.length === 0 && requests.enCurso === 0
                icon: "❓"
                title: qsTr("Aún no hay preguntas")
                message: qsTr("Las preguntas que guarde aparecerán aquí.")
            }

            Repeater {
                model: root.preguntas
                delegate: Card {
                    id: tarjeta
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    padding: Theme.spacingM

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Theme.spacingS

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: (tarjeta.index + 1) + ". " + tarjeta.modelData.enunciado
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Badge { text: root.nombreTipo(tarjeta.modelData.tipo) }
                            ToolButton {
                                text: "🗑"
                                ToolTip.visible: hovered
                                ToolTip.text: qsTr("Eliminar pregunta")
                                onClicked: { confirmar.pregunta = tarjeta.modelData; confirmar.open() }
                            }
                        }

                        Adjunto {
                            Layout.fillWidth: true
                            visible: tarjeta.modelData.archivoDisponible === true
                            url: tarjeta.modelData.archivoDisponible ? tarjeta.modelData.archivoUrl : ""
                            nombre: tarjeta.modelData.nombreArchivo || ""
                            esImagen: tarjeta.modelData.archivoEsImagen === true
                            alturaMaxima: 220
                        }

                        Repeater {
                            model: tarjeta.modelData.opciones || []
                            delegate: Label {
                                required property var modelData
                                text: (modelData.esCorrecta ? "✔  " : "○  ") + modelData.texto
                                color: modelData.esCorrecta ? Theme.successDark : Theme.textSecondary
                                font.weight: modelData.esCorrecta ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.spacingL }
        }
    }

    Dialog {
        id: confirmar
        property var pregunta: null
        anchors.centerIn: parent
        modal: true
        title: qsTr("Eliminar pregunta")
        standardButtons: Dialog.Yes | Dialog.No
        width: Math.min(root.width - 40, 420)
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: confirmar.pregunta ? qsTr("¿Eliminar «%1»? No se puede deshacer.").arg(confirmar.pregunta.enunciado) : ""
        }
        onAccepted: root.eliminar(pregunta)
    }
}
