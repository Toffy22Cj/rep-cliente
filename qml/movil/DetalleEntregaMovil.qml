import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Profesor: respuestas de un estudiante, nota y observaciones; «Guardar y siguiente». */
Page {
    id: root
    property var actividad: null
    property var entregas: []
    property int indice: 0
    property var detalle: null
    property bool guardando: false
    readonly property var entrega: entregas[indice]

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: root.entrega ? root.entrega.nombreEstudiante : ""
        subtitle: qsTr("%1 de %2").arg(root.indice + 1).arg(root.entregas.length)
    }

    ApiRequests { id: requests }

    function cargar() {
        detalle = null
        notaField.text = entrega.nota !== null && entrega.nota !== undefined ? Number(entrega.nota).toFixed(1) : ""
        obsField.text = entrega.observaciones || ""
        requests.get("/actividades/" + actividad.id + "/respuestas/" + entrega.estudianteId,
                     d => { detalle = d }, m => toastGlobal.mostrar(m, "error"))
    }

    function guardar() {
        const valor = parseFloat(notaField.text.replace(",", "."))
        if (isNaN(valor) || valor < 0 || valor > 5) { toastGlobal.mostrar(qsTr("La nota debe estar entre 0.0 y 5.0"), "error"); return }
        guardando = true
        requests.put("/actividades/" + actividad.id + "/notas/" + entrega.estudianteId + "?nota=" + valor
                     + "&observaciones=" + encodeURIComponent(obsField.text.trim()), null, () => {
            guardando = false
            toastGlobal.mostrar(qsTr("Nota guardada"), "exito")
            // Siguiente sin revisar (o volver a la lista si no quedan)
            const actual = root.indice
            const sigue = root.entregas.findIndex((e, i) => i > actual && !e.calificada)
            if (sigue >= 0) { root.indice = sigue; root.cargar() } else stackView.pop()
        }, m => { guardando = false; toastGlobal.mostrar(m, "error") })
    }

    Component.onCompleted: cargar()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ColumnLayout {
                width: scroll.availableWidth - 2 * Theme.spacingM
                x: Theme.spacingM
                y: Theme.spacingM
                spacing: Theme.spacingS
                BusyIndicator { visible: root.detalle === null; running: visible; Layout.alignment: Qt.AlignHCenter }
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
                                wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.textPrimary
                            }
                        }
                    }
                }
                Item { Layout.preferredHeight: Theme.spacingS }
            }
        }

        // Nota fija abajo, sobre el teclado
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pie.implicitHeight + 2 * Theme.spacingM
            color: Theme.surface
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Theme.border }
            ColumnLayout {
                id: pie
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS
                RowLayout {
                    Layout.fillWidth: true
                    AppTextField {
                        id: notaField
                        Layout.preferredWidth: 110
                        label: qsTr("Nota 0–5")
                        field.inputMethodHints: Qt.ImhFormattedNumbersOnly
                        field.validator: RegularExpressionValidator { regularExpression: /^[0-5]([.,]\d)?$/ }
                    }
                    AppTextField { id: obsField; Layout.fillWidth: true; label: qsTr("Observaciones") }
                }
                AppButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    text: root.guardando ? qsTr("Guardando…") : qsTr("Guardar y siguiente")
                    enabled: !root.guardando && notaField.text !== "" && sincronizacion.enLinea
                    onClicked: root.guardar()
                }
            }
        }
    }
}
