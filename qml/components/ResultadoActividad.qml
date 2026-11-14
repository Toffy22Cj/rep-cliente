import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

/*
 * Resultado de una actividad entregada: nota, observaciones del profesor y, si el
 * profesor lo permite, la respuesta del estudiante y la correcta en cada pregunta.
 *   ResultadoActividad { id: resultado }   →   resultado.abrir(actividadId, "Título")
 */
Dialog {
    id: root
    property var datos: null
    property string error: ""
    property string titulo: ""

    function abrir(actividadId, tituloActividad) {
        titulo = tituloActividad || ""
        datos = null
        error = ""
        open()
        requests.get("/estudiante/" + sessionManager.userId + "/actividades/" + actividadId + "/resultado",
                     d => { datos = d }, m => { error = m })
    }

    function nota(n) { return n === null || n === undefined ? "—" : Number(n).toFixed(1) }

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: Math.min(parent ? parent.width - 40 : 640, 680)
    height: Math.min(parent ? parent.height - 80 : 600, 620)
    title: titulo
    standardButtons: Dialog.Close

    ApiRequests { id: requests }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: Theme.spacingS

            BusyIndicator { visible: root.datos === null && root.error === ""; running: visible; Layout.alignment: Qt.AlignHCenter }
            Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }

            RowLayout {
                visible: root.datos !== null
                spacing: Theme.spacingM
                Label { text: "✔ " + qsTr("Hecho"); font.pixelSize: Theme.fontTitle; font.weight: Font.Bold; color: Theme.successDark }
                Item { Layout.fillWidth: true }
                Label { text: qsTr("Nota"); color: Theme.textSecondary }
                Label {
                    text: root.nota(root.datos ? root.datos.nota : null)
                    font.pixelSize: Theme.fontHeadline
                    font.weight: Font.Bold
                    color: root.datos && root.datos.nota >= 3.0 ? Theme.successDark : Theme.dangerDark
                }
            }

            Label {
                visible: !!(root.datos && root.datos.observaciones)
                text: root.datos && root.datos.observaciones ? qsTr("Observaciones del profesor: %1").arg(root.datos.observaciones) : ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: Theme.textPrimary
            }

            Rectangle {
                visible: !!(root.datos && root.datos.respuestasVisibles === false)
                Layout.fillWidth: true
                implicitHeight: oculto.implicitHeight + 2 * Theme.spacingS
                radius: Theme.radiusM
                color: Theme.infoSoft
                Label {
                    id: oculto
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    wrapMode: Text.WordWrap
                    color: Theme.textPrimary
                    text: qsTr("El profesor decidió no mostrar las respuestas correctas de esta actividad.")
                }
            }

            Repeater {
                model: root.datos && root.datos.resultadosPreguntas ? root.datos.resultadosPreguntas : []
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool abierta: modelData.respuestaCorrecta === null || modelData.respuestaCorrecta === undefined
                    Layout.fillWidth: true
                    implicitHeight: col.implicitHeight + 2 * Theme.spacingS
                    radius: Theme.radiusM
                    color: abierta ? Theme.warningSoft : modelData.esCorrecta ? Theme.successSoft : Theme.dangerSoft
                    ColumnLayout {
                        id: col
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: 2
                        Label {
                            text: (index + 1) + ". " + (modelData.enunciado || "")
                            font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.textPrimary
                        }
                        Label {
                            text: (abierta ? "" : (modelData.esCorrecta ? "✔ " : "✖ ")) + qsTr("Su respuesta: %1")
                                  .arg(modelData.respuestaEstudiante || qsTr("(sin responder)"))
                            wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.textPrimary
                        }
                        Label {
                            visible: !abierta && !modelData.esCorrecta
                            text: qsTr("Respuesta correcta: %1").arg(modelData.respuestaCorrecta || "")
                            wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.successDark; font.weight: Font.DemiBold
                        }
                        Label {
                            visible: abierta
                            text: qsTr("Pregunta abierta: la revisa el profesor.")
                            font.pixelSize: Theme.fontCaption; color: Theme.warning
                        }
                    }
                }
            }
        }
    }
}
