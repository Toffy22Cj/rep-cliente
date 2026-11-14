import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Horario (estudiante: su curso; profesor: sus clases). Hoy o la semana completa. */
Item {
    id: root
    property var bloques: []
    property bool soloHoy: true
    readonly property bool esProfesor: sessionManager.userRole === "PROFESOR"
    /** Profesor: la shell abre la pestaña de asistencia con esta clase. */
    signal abrirAsistencia(var bloque)

    ApiRequests { id: requests }
    function cargar() {
        requests.get(esProfesor ? "/profesor/horario" : "/estudiante/" + sessionManager.userId + "/horario",
                     d => { bloques = d || [] }, m => toastGlobal.mostrar(m, "error"))
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
                AppButton { text: qsTr("Hoy"); variant: root.soloHoy ? "primary" : "secondary"; onClicked: root.soloHoy = true }
                AppButton { text: qsTr("Semana"); variant: root.soloHoy ? "secondary" : "primary"; onClicked: root.soloHoy = false }
                Item { Layout.fillWidth: true }
                ToolButton { text: "↻"; font.pixelSize: 20; onClicked: root.cargar() }
            }
            Label {
                visible: root.bloques.length === 0 && requests.enCurso === 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                text: qsTr("La administración aún no ha publicado el horario.")
            }
            VistaHorario {
                Layout.fillWidth: true
                bloques: root.bloques
                soloHoy: root.soloHoy
                detalle: root.esProfesor ? "curso" : "profesor"
                onBloqueElegido: b => { if (root.esProfesor) root.abrirAsistencia(b) }
            }
            Label {
                visible: root.esProfesor && root.bloques.length > 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.pixelSize: Theme.fontCaption
                text: qsTr("Toque una clase para tomar la asistencia.")
            }
        }
    }
}
