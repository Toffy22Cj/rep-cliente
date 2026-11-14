import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Boletín del estudiante: promedio y desempeño por materia, estado de cada actividad,
 * faltas y detalle de la corrección. Funciona sin conexión con los últimos datos.
 */
Page {
    id: root
    property var boletin: null
    property string error: ""
    property var expandidas: ({})

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: qsTr("Mis notas")
        subtitle: root.boletin ? qsTr("Curso %1 · %2 · actualizado %3").arg(root.boletin.curso)
                                 .arg(root.boletin.periodo ? root.boletin.periodo.nombre : root.boletin.ponderado ? qsTr("año completo") : qsTr("todas las actividades"))
                                 .arg(Qt.formatDateTime(new Date(root.boletin.generadoEn), "dd/MM HH:mm")) : ""
        SelectorPeriodo { id: selector; onCambiado: root.cargar() }
        AppButton {
            text: qsTr("⬇ Boletín PDF")
            variant: "secondary"
            onClicked: api.abrir("/api/estudiante/" + sessionManager.userId + "/notas/pdf" + selector.parametro("?"))
        }
        AppButton {
            text: qsTr("↻ Actualizar")
            variant: "secondary"
            onClicked: root.cargar()
        }
    }

    ApiRequests { id: requests }

    function cargar() {
        requests.get("/estudiante/" + sessionManager.userId + "/notas" + selector.parametro("?"),
                     datos => { boletin = datos; error = "" },
                     mensaje => { error = mensaje })
    }

    function nota(n) { return n === null || n === undefined ? "—" : Number(n).toFixed(1) }

    function colorNota(n) {
        if (n === null || n === undefined) return Theme.textMuted
        return n >= (boletin ? boletin.notaMinimaAprobatoria : 3.0) ? Theme.successDark : Theme.dangerDark
    }

    function desempenoTexto(d) {
        return d === "SUPERIOR" ? qsTr("Superior") : d === "ALTO" ? qsTr("Alto")
             : d === "BASICO" ? qsTr("Básico") : d === "BAJO" ? qsTr("Bajo") : "—"
    }

    readonly property var estados: ({
        "PENDIENTE": { texto: qsTr("Pendiente"), tint: Theme.info, soft: Theme.infoSoft },
        "EN_CURSO": { texto: qsTr("En curso"), tint: Theme.warning, soft: Theme.warningSoft },
        "ENTREGADA": { texto: qsTr("Por revisar"), tint: Theme.purple, soft: Theme.primarySoft },
        "CALIFICADA": { texto: qsTr("Calificada"), tint: Theme.successDark, soft: Theme.successSoft },
        "VENCIDA": { texto: qsTr("No entregada"), tint: Theme.dangerDark, soft: Theme.dangerSoft }
    })

    function verDetalle(actividad) {
        detalle.actividad = actividad
        detalle.resultado = null
        detalle.open()
        requests.get("/estudiante/" + sessionManager.userId + "/actividades/" + actividad.actividadId + "/resultado",
                     datos => { detalle.resultado = datos },
                     mensaje => { detalle.resultado = { error: mensaje } })
    }

    Component.onCompleted: cargar()

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: Math.min(scroll.availableWidth - 2 * Theme.spacingXl, Theme.maxContentWidth)
            x: (scroll.availableWidth - width) / 2
            y: Theme.spacingL
            spacing: Theme.spacingM

            Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }

            // ------------------------------------------------ resumen
            GridLayout {
                Layout.fillWidth: true
                visible: root.boletin !== null
                columns: root.width > 900 ? 3 : 1
                columnSpacing: Theme.spacingM
                StatCard {
                    title: qsTr("Promedio general · %1").arg(root.desempenoTexto(root.boletin ? root.boletin.desempenoGeneral : null))
                    value: root.nota(root.boletin ? root.boletin.promedioGeneral : null)
                    icon: "🎓"
                    color: Theme.primary
                }
                StatCard {
                    title: qsTr("Materias aprobadas")
                    value: root.boletin ? root.boletin.materiasAprobadas : 0
                    icon: "✅"
                    color: Theme.success
                }
                StatCard {
                    title: qsTr("Materias en riesgo (bajo %1)").arg(root.nota(root.boletin ? root.boletin.notaMinimaAprobatoria : 3))
                    value: root.boletin ? root.boletin.materiasReprobadas : 0
                    icon: "⚠️"
                    color: Theme.danger
                }
            }

            EmptyState {
                Layout.fillWidth: true
                visible: root.boletin !== null && root.boletin.materias.length === 0
                title: qsTr("Aún no hay materias con actividades")
            }

            // ------------------------------------------------ materias
            Repeater {
                model: root.boletin ? root.boletin.materias : []
                delegate: Card {
                    id: tarjeta
                    required property var modelData
                    readonly property bool abierta: root.expandidas[modelData.materiaId] === true
                    readonly property int noEntregadas: modelData.actividades.filter(a => a.estado === "VENCIDA").length
                    Layout.fillWidth: true
                    padding: Theme.spacingM

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Theme.spacingS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingM
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label { text: tarjeta.modelData.materia; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; color: Theme.textPrimary }
                                Label {
                                    text: tarjeta.modelData.profesor + " · "
                                          + qsTr("%n calificada(s)", "", tarjeta.modelData.calificadas) + " · "
                                          + qsTr("%n pendiente(s)", "", tarjeta.modelData.pendientes) + " · "
                                          + (tarjeta.noEntregadas > 0 ? qsTr("%n sin entregar", "", tarjeta.noEntregadas) + " · " : "")
                                          + qsTr("%n falta(s)", "", tarjeta.modelData.asistencia.ausencias)
                                          + (tarjeta.modelData.asistencia.retardos > 0 ? " · " + qsTr("%n retardo(s)", "", tarjeta.modelData.asistencia.retardos) : "")
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontCaption
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                            ColumnLayout {
                                spacing: 0
                                Label {
                                    Layout.alignment: Qt.AlignRight
                                    text: root.nota(tarjeta.modelData.promedio)
                                    font.pixelSize: Theme.fontHeadline
                                    font.weight: Font.Bold
                                    color: root.colorNota(tarjeta.modelData.promedio)
                                }
                                Label {
                                    Layout.alignment: Qt.AlignRight
                                    visible: !!tarjeta.modelData.desempeno
                                    text: root.desempenoTexto(tarjeta.modelData.desempeno)
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontCaption
                                }
                            }
                            ToolButton {
                                text: tarjeta.abierta ? "▲" : "▼"
                                Accessible.name: tarjeta.abierta ? qsTr("Ocultar actividades") : qsTr("Ver actividades")
                                onClicked: {
                                    const e = Object.assign({}, root.expandidas)
                                    e[tarjeta.modelData.materiaId] = !tarjeta.abierta
                                    root.expandidas = e
                                }
                            }
                        }

                        // Nota de cada periodo (solo en la vista de año completo)
                        Flow {
                            Layout.fillWidth: true
                            visible: tarjeta.modelData.periodos && tarjeta.modelData.periodos.length > 0
                            spacing: Theme.spacingS
                            Repeater {
                                model: tarjeta.modelData.periodos || []
                                delegate: Badge {
                                    required property var modelData
                                    text: modelData.nombre + " (" + modelData.porcentaje + " %): " + root.nota(modelData.promedio)
                                    tint: modelData.promedio === null ? Theme.textMuted : root.colorNota(modelData.promedio)
                                    softTint: Theme.surfaceAlt
                                }
                            }
                        }

                        Repeater {
                            model: tarjeta.abierta ? tarjeta.modelData.actividades : []
                            delegate: ItemDelegate {
                                id: fila
                                required property var modelData
                                readonly property var info: root.estados[modelData.estado]
                                readonly property bool conDetalle: modelData.estado === "CALIFICADA" || modelData.estado === "ENTREGADA"
                                Layout.fillWidth: true
                                enabled: conDetalle
                                onClicked: root.verDetalle(modelData)
                                background: Rectangle { color: fila.hovered ? Theme.surfaceAlt : "transparent"; radius: Theme.radiusS }
                                contentItem: RowLayout {
                                    spacing: Theme.spacingM
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Label { text: fila.modelData.titulo; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Label {
                                            text: fila.modelData.tipo + (fila.modelData.fechaEntrega ? " · " + qsTr("entrega %1").arg(fila.modelData.fechaEntrega) : "")
                                                  + (fila.modelData.observaciones ? " · “" + fila.modelData.observaciones + "”" : "")
                                            color: Theme.textMuted
                                            font.pixelSize: Theme.fontCaption
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    Badge { text: fila.info.texto; tint: fila.info.tint; softTint: fila.info.soft }
                                    Label {
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                        text: root.nota(fila.modelData.nota)
                                        font.weight: Font.DemiBold
                                        color: root.colorNota(fila.modelData.nota)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.spacingL }
        }
    }

    BusyIndicator { anchors.centerIn: parent; running: requests.enCurso > 0 && root.boletin === null; visible: running }

    // ------------------------------------------------ detalle de corrección
    Dialog {
        id: detalle
        property var actividad: null
        property var resultado: null
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 640)
        height: Math.min(root.height - 80, 560)
        title: actividad ? actividad.titulo : ""
        standardButtons: Dialog.Close

        ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: Theme.spacingS
                Label {
                    visible: detalle.resultado !== null && detalle.resultado.error === undefined
                    text: detalle.resultado ? qsTr("Nota: %1").arg(root.nota(detalle.resultado.nota)) : ""
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                    color: root.colorNota(detalle.resultado ? detalle.resultado.nota : null)
                }
                Label {
                    visible: detalle.resultado && !!detalle.resultado.observaciones
                    text: detalle.resultado && detalle.resultado.observaciones ? qsTr("Observaciones del profesor: %1").arg(detalle.resultado.observaciones) : ""
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                }
                Label {
                    visible: detalle.resultado && detalle.resultado.error !== undefined
                    text: detalle.resultado && detalle.resultado.error ? detalle.resultado.error : ""
                    color: Theme.danger
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Repeater {
                    model: detalle.resultado && detalle.resultado.resultadosPreguntas ? detalle.resultado.resultadosPreguntas : []
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: textoRetro.implicitHeight + 2 * Theme.spacingS
                        radius: Theme.radiusS
                        color: modelData.esCorrecta ? Theme.successSoft : Theme.surfaceAlt
                        Label {
                            id: textoRetro
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            wrapMode: Text.WordWrap
                            text: (index + 1) + ". " + (modelData.esCorrecta ? "✔ " : "") + modelData.retroalimentacion
                            color: Theme.textPrimary
                        }
                    }
                }
                BusyIndicator { visible: detalle.resultado === null; running: visible; Layout.alignment: Qt.AlignHCenter }
            }
        }
    }
}
