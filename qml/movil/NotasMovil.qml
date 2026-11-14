import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Estudiante: boletín por periodo o año, por materia, con el detalle de cada actividad. */
Item {
    id: root
    property var boletin: null
    property string error: ""
    property var expandidas: ({})

    ApiRequests { id: requests }
    ResultadoActividad { id: resultado }

    function cargar() {
        requests.get("/estudiante/" + sessionManager.userId + "/notas" + selector.parametro("?"),
                     d => { boletin = d; error = "" }, m => { error = m })
    }
    function nota(n) { return n === null || n === undefined ? "—" : Number(n).toFixed(1) }
    function colorNota(n) {
        if (n === null || n === undefined) return Theme.textMuted
        return n >= (boletin ? boletin.notaMinimaAprobatoria : 3.0) ? Theme.successDark : Theme.dangerDark
    }
    function desempeno(d) {
        return d === "SUPERIOR" ? qsTr("Superior") : d === "ALTO" ? qsTr("Alto") : d === "BASICO" ? qsTr("Básico") : d === "BAJO" ? qsTr("Bajo") : ""
    }
    readonly property var estados: ({
        "PENDIENTE": qsTr("Pendiente"), "EN_CURSO": qsTr("En curso"), "ENTREGADA": qsTr("Por revisar"),
        "CALIFICADA": qsTr("Calificada"), "VENCIDA": qsTr("No entregada")
    })

    Component.onCompleted: cargar()

    Flickable {
        anchors.fill: parent
        contentHeight: columna.implicitHeight + 2 * Theme.spacingM
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: columna
            width: parent.width - 2 * Theme.spacingM
            x: Theme.spacingM
            y: Theme.spacingM
            spacing: Theme.spacingS

            RowLayout {
                Layout.fillWidth: true
                SelectorPeriodo { id: selector; Layout.fillWidth: true; onCambiado: root.cargar() }
                ToolButton { text: "⬇ PDF"; onClicked: api.abrir("/api/estudiante/" + sessionManager.userId + "/notas/pdf" + selector.parametro("?")) }
                ToolButton { text: "↻"; font.pixelSize: 20; onClicked: root.cargar() }
            }

            Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            BusyIndicator { visible: root.boletin === null && root.error === ""; running: visible; Layout.alignment: Qt.AlignHCenter }

            Card {
                Layout.fillWidth: true
                visible: root.boletin !== null
                padding: Theme.spacingM
                RowLayout {
                    anchors.fill: parent
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: qsTr("Promedio general"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                        Label {
                            text: root.boletin ? (root.boletin.periodo ? root.boletin.periodo.nombre : root.boletin.ponderado ? qsTr("Año completo") : qsTr("Todas las actividades")) : ""
                            color: Theme.textMuted; font.pixelSize: Theme.fontCaption
                        }
                        Label {
                            text: root.boletin ? qsTr("%1 aprobada(s) · %2 en riesgo").arg(root.boletin.materiasAprobadas).arg(root.boletin.materiasReprobadas) : ""
                            color: Theme.textSecondary; font.pixelSize: Theme.fontCaption
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: root.nota(root.boletin ? root.boletin.promedioGeneral : null)
                            font.pixelSize: Theme.fontHeadline; font.weight: Font.Bold
                            color: root.colorNota(root.boletin ? root.boletin.promedioGeneral : null)
                        }
                        Label { Layout.alignment: Qt.AlignRight; text: root.desempeno(root.boletin ? root.boletin.desempenoGeneral : null); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                    }
                }
            }

            Repeater {
                model: root.boletin ? root.boletin.materias : []
                delegate: Card {
                    id: tarjeta
                    required property var modelData
                    readonly property bool abierta: root.expandidas[modelData.materiaId] === true
                    Layout.fillWidth: true
                    padding: Theme.spacingM
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Theme.spacingXs
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Label { text: tarjeta.modelData.materia; font.weight: Font.DemiBold; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                                Label {
                                    text: qsTr("%n falta(s)", "", tarjeta.modelData.asistencia.ausencias)
                                          + (tarjeta.modelData.asistencia.retardos > 0 ? " · " + qsTr("%n retardo(s)", "", tarjeta.modelData.asistencia.retardos) : "")
                                    color: Theme.textMuted; font.pixelSize: Theme.fontCaption
                                }
                            }
                            ColumnLayout {
                                spacing: 0
                                Label { Layout.alignment: Qt.AlignRight; text: root.nota(tarjeta.modelData.promedio); font.pixelSize: Theme.fontTitle; font.weight: Font.Bold; color: root.colorNota(tarjeta.modelData.promedio) }
                                Label { Layout.alignment: Qt.AlignRight; text: root.desempeno(tarjeta.modelData.desempeno); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                            }
                        }
                        Flow {
                            Layout.fillWidth: true
                            visible: tarjeta.modelData.periodos && tarjeta.modelData.periodos.length > 0
                            spacing: Theme.spacingXs
                            Repeater {
                                model: tarjeta.modelData.periodos || []
                                delegate: Badge {
                                    required property var modelData
                                    text: modelData.nombre + ": " + root.nota(modelData.promedio)
                                    tint: modelData.promedio === null ? Theme.textMuted : root.colorNota(modelData.promedio)
                                    softTint: Theme.surfaceAlt
                                }
                            }
                        }
                        AppButton {
                            Layout.fillWidth: true
                            visible: tarjeta.modelData.actividades.length > 0
                            variant: "secondary"
                            text: (tarjeta.abierta ? "▲ " : "▼ ") + qsTr("%n actividad(es)", "", tarjeta.modelData.actividades.length)
                            onClicked: {
                                const e = Object.assign({}, root.expandidas)
                                e[tarjeta.modelData.materiaId] = !tarjeta.abierta
                                root.expandidas = e
                            }
                        }
                        Repeater {
                            model: tarjeta.abierta ? tarjeta.modelData.actividades : []
                            delegate: ItemDelegate {
                                id: fila
                                required property var modelData
                                readonly property bool conDetalle: modelData.estado === "CALIFICADA" || modelData.estado === "ENTREGADA"
                                Layout.fillWidth: true
                                enabled: conDetalle
                                onClicked: resultado.abrir(modelData.actividadId, modelData.titulo)
                                contentItem: RowLayout {
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Label { text: fila.modelData.titulo; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Label { text: root.estados[fila.modelData.estado] || fila.modelData.estado; color: Theme.textMuted; font.pixelSize: Theme.fontCaption }
                                    }
                                    Label { text: root.nota(fila.modelData.nota); font.weight: Font.DemiBold; color: root.colorNota(fila.modelData.nota) }
                                    Label { visible: fila.conDetalle; text: "›"; font.pixelSize: 20; color: Theme.textMuted }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
