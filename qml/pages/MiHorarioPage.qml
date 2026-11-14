import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Horario de clases del estudiante (su curso) o del profesor (sus clases). Funciona sin
 * conexión con la última copia. Al profesor, tocar una clase le abre la asistencia.
 */
Page {
    id: root
    property var bloques: []
    property string error: ""
    readonly property bool esProfesor: sessionManager.userRole === "PROFESOR"
    signal abrirAsistencia(var bloque)

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: qsTr("Mi horario")
        subtitle: qsTr("%n clase(s) por semana", "", root.bloques.length)
    }

    ApiRequests { id: requests }

    function cargar() {
        const ruta = esProfesor ? "/profesor/horario" : "/estudiante/" + sessionManager.userId + "/horario"
        requests.get(ruta, d => { bloques = d || []; error = "" }, m => { error = m })
    }
    Component.onCompleted: cargar()

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: scroll.availableWidth - 2 * Theme.spacingL
            x: Theme.spacingL
            y: Theme.spacingL
            spacing: Theme.spacingM
            Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            EmptyState {
                Layout.fillWidth: true
                visible: root.bloques.length === 0 && requests.enCurso === 0 && root.error === ""
                title: qsTr("Aún no hay horario")
                message: qsTr("La administración del colegio publica el horario de clases.")
            }
            VistaHorario {
                Layout.fillWidth: true
                visible: root.bloques.length > 0
                bloques: root.bloques
                detalle: root.esProfesor ? "curso" : "profesor"
                onBloqueElegido: b => { if (root.esProfesor) root.abrirAsistencia(b) }
            }
            Item { Layout.preferredHeight: Theme.spacingL }
        }
    }
}
