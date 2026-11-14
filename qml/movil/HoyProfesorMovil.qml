import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Profesor: clases de hoy (tocar → asistencia) y entregas por revisar. */
Item {
    id: root
    property var bloques: []
    property var resumen: null
    signal abrirAsistencia(var bloque)
    signal irAPestana(string archivo)

    ApiRequests { id: requests }
    function cargar() {
        requests.get("/profesor/horario", d => { bloques = d || [] })
        requests.get("/actividades/dashboard", d => { resumen = d })
    }
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
            spacing: Theme.spacingM

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { text: qsTr("Hola, %1").arg(sessionManager.userName); font.pixelSize: Theme.fontTitle; font.weight: Font.Bold; color: Theme.textPrimary }
                    Label { text: Qt.locale("es_CO").toString(new Date(), "dddd d 'de' MMMM"); color: Theme.textSecondary }
                }
                ToolButton { text: "↻"; font.pixelSize: 20; onClicked: root.cargar() }
            }

            Card {
                Layout.fillWidth: true
                padding: Theme.spacingM
                visible: root.resumen !== null
                RowLayout {
                    anchors.fill: parent
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: qsTr("Entregas por revisar"); color: Theme.textSecondary }
                        Label {
                            text: root.resumen ? String(root.resumen.entregasPendientes) : "0"
                            font.pixelSize: Theme.fontHeadline; font.weight: Font.Bold
                            color: root.resumen && root.resumen.entregasPendientes > 0 ? Theme.warning : Theme.successDark
                        }
                    }
                    AppButton { text: qsTr("Calificar"); onClicked: root.irAPestana("CalificarMovil.qml") }
                }
            }

            Label { text: qsTr("Clases de hoy"); font.weight: Font.DemiBold; color: Theme.textPrimary }
            VistaHorario {
                Layout.fillWidth: true
                bloques: root.bloques
                soloHoy: true
                detalle: "curso"
                onBloqueElegido: b => root.abrirAsistencia(b)
            }
            Label {
                visible: root.bloques.length > 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.pixelSize: Theme.fontCaption
                text: qsTr("Toque una clase para tomar la asistencia.")
            }
        }
    }
}
