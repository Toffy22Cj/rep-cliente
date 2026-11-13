import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Calificación de una actividad (vista dividida): a la izquierda las entregas, a la
 * derecha las respuestas del estudiante seleccionado con la nota y las observaciones.
 * Antes la lista se pedía a una ruta inexistente y la pantalla quedaba vacía.
 */
Page {
    id: root
    property int actividadId: 0
    property string actividadTitulo: qsTr("Calificar")
    property var entregas: []
    property var seleccion: null
    property var detalle: null
    property string error: ""
    property bool guardando: false

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: root.actividadTitulo
        subtitle: qsTr("%n entrega(s) · %1 por revisar", "", root.entregas.length)
                  .arg(root.entregas.filter(e => !e.calificada).length)
    }

    ApiRequests { id: requests }
    Toast { id: toast }

    function nota(n) { return n === null || n === undefined ? "—" : Number(n).toFixed(1) }

    function cargar(seleccionarId) {
        requests.get("/profesor/actividades/" + actividadId + "/respuestas", datos => {
            entregas = datos || []
            const objetivo = entregas.find(e => e.estudianteId === seleccionarId) || entregas[0]
            if (objetivo) seleccionar(objetivo)
        }, mensaje => { error = mensaje })
    }

    function seleccionar(entrega) {
        seleccion = entrega
        detalle = null
        notaField.text = entrega.nota !== null ? Number(entrega.nota).toFixed(1) : ""
        obsField.text = entrega.observaciones || ""
        requests.get("/actividades/" + actividadId + "/respuestas/" + entrega.estudianteId,
                     datos => { detalle = datos }, mensaje => { error = mensaje })
    }

    function guardar() {
        const valor = parseFloat(notaField.text.replace(",", "."))
        if (isNaN(valor) || valor < 0 || valor > 5) { error = qsTr("La nota debe estar entre 0.0 y 5.0"); return }
        error = ""
        guardando = true
        const id = seleccion.estudianteId
        requests.put("/actividades/" + actividadId + "/notas/" + id + "?nota=" + valor
                     + "&observaciones=" + encodeURIComponent(obsField.text.trim()), null, () => {
            guardando = false
            toast.mostrar(qsTr("Calificación guardada"), "exito")
            // Avanza a la siguiente entrega sin revisar
            const pendiente = entregas.find(e => !e.calificada && e.estudianteId !== id)
            cargar(pendiente ? pendiente.estudianteId : id)
        }, mensaje => { guardando = false; error = mensaje })
    }

    Component.onCompleted: if (actividadId > 0) cargar()

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingM

        // ------------------------------------------------ entregas
        Card {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            padding: Theme.spacingS
            ListView {
                id: lista
                anchors.fill: parent
                clip: true
                model: root.entregas
                spacing: 2
                ScrollBar.vertical: ScrollBar {}
                EmptyState {
                    anchors.centerIn: parent
                    visible: lista.count === 0 && requests.enCurso === 0
                    title: qsTr("Sin entregas todavía")
                }
                delegate: ItemDelegate {
                    id: item
                    required property var modelData
                    width: ListView.view.width
                    highlighted: root.seleccion && root.seleccion.estudianteId === modelData.estudianteId
                    onClicked: root.seleccionar(modelData)
                    background: Rectangle {
                        radius: Theme.radiusS
                        color: item.highlighted ? Theme.primarySoft : item.hovered ? Theme.surfaceAlt : "transparent"
                    }
                    contentItem: RowLayout {
                        spacing: Theme.spacingS
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label { text: item.modelData.nombreEstudiante; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label {
                                text: item.modelData.calificada ? qsTr("Revisada") : qsTr("Por revisar")
                                color: item.modelData.calificada ? Theme.successDark : Theme.warning
                                font.pixelSize: Theme.fontCaption
                            }
                        }
                        Label { text: root.nota(item.modelData.nota); font.weight: Font.DemiBold; color: Theme.textPrimary }
                    }
                }
            }
        }

        // ------------------------------------------------ detalle y calificación
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.seleccion !== null

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacingS

                Label {
                    text: root.seleccion ? root.seleccion.nombreEstudiante : ""
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
                Label {
                    text: root.detalle && root.detalle.fechaEntrega
                          ? qsTr("Entregada el %1").arg(Qt.formatDateTime(new Date(root.detalle.fechaEntrega), "dd/MM/yyyy HH:mm")) : ""
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        width: parent.width
                        spacing: Theme.spacingS
                        Repeater {
                            model: root.detalle ? root.detalle.respuestasPreguntas : []
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool abierta: modelData.opcionId === null || modelData.opcionId === undefined
                                Layout.fillWidth: true
                                implicitHeight: col.implicitHeight + 2 * Theme.spacingS
                                radius: Theme.radiusM
                                color: abierta ? Theme.warningSoft : modelData.esCorrecta ? Theme.successSoft : Theme.dangerSoft
                                ColumnLayout {
                                    id: col
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    spacing: 2
                                    Label { text: (index + 1) + ". " + modelData.enunciado; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.textPrimary }
                                    Label {
                                        text: abierta ? (modelData.respuestaAbierta || qsTr("(sin respuesta)"))
                                                      : (modelData.esCorrecta ? "✔ " : "✖ ") + (modelData.opcionTexto || qsTr("(sin respuesta)"))
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                        color: Theme.textPrimary
                                    }
                                    Label { visible: abierta; text: qsTr("Respuesta abierta: revísela y ajuste la nota."); font.pixelSize: Theme.fontCaption; color: Theme.warning }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM
                    AppTextField {
                        id: notaField
                        label: qsTr("Nota (0.0 – 5.0)")
                        Layout.preferredWidth: 140
                        field.validator: RegularExpressionValidator { regularExpression: /^[0-5]([.,]\d)?$/ }
                    }
                    AppTextField {
                        id: obsField
                        label: qsTr("Observaciones para el estudiante")
                        Layout.fillWidth: true
                    }
                    AppButton {
                        Layout.alignment: Qt.AlignBottom
                        text: root.guardando ? qsTr("Guardando…") : qsTr("Guardar y siguiente")
                        enabled: !root.guardando && notaField.text !== "" && sincronizacion.enLinea
                        onClicked: root.guardar()
                    }
                }
                Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
        }
    }
}
