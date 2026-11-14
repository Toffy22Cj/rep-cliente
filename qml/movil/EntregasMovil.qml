import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Profesor: entregas de una actividad; primero las que faltan por revisar. */
Page {
    id: root
    property var actividad: null
    property var entregas: []

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: root.actividad ? root.actividad.titulo : ""
        subtitle: qsTr("%n entrega(s) · %1 por revisar", "", root.entregas.length).arg(root.entregas.filter(e => !e.calificada).length)
    }

    ApiRequests { id: requests }
    function nota(n) { return n === null || n === undefined ? "—" : Number(n).toFixed(1) }
    function cargar() {
        requests.get("/profesor/actividades/" + actividad.id + "/respuestas", d => {
            entregas = (d || []).slice().sort((a, b) => (a.calificada === b.calificada ? 0 : a.calificada ? 1 : -1))
        }, m => toastGlobal.mostrar(m, "error"))
    }
    Component.onCompleted: cargar()
    StackView.onActivated: cargar() // al volver del detalle se ve la nota guardada

    ListView {
        id: lista
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        clip: true
        spacing: Theme.spacingXs
        model: root.entregas
        delegate: ItemDelegate {
            id: fila
            required property var modelData
            required property int index
            width: ListView.view.width
            padding: Theme.spacingM
            background: Rectangle { radius: Theme.radiusM; color: fila.pressed ? Theme.surfaceAlt : Theme.surface; border.color: Theme.border }
            onClicked: stackView.push(Qt.resolvedUrl("DetalleEntregaMovil.qml"),
                                      { actividad: root.actividad, entregas: root.entregas, indice: fila.index })
            contentItem: RowLayout {
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { text: fila.modelData.nombreEstudiante; color: Theme.textPrimary; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label {
                        text: fila.modelData.calificada ? qsTr("Revisada") : qsTr("Por revisar")
                        color: fila.modelData.calificada ? Theme.successDark : Theme.warning
                        font.pixelSize: Theme.fontCaption
                    }
                }
                Label { text: root.nota(fila.modelData.nota); font.pixelSize: Theme.fontSubtitle; font.weight: Font.Bold; color: Theme.textPrimary }
                Label { text: "›"; font.pixelSize: 22; color: Theme.textMuted }
            }
        }
        Label {
            anchors.centerIn: parent
            visible: lista.count === 0 && requests.enCurso === 0
            color: Theme.textMuted
            text: qsTr("Aún no hay entregas")
        }
    }
}
