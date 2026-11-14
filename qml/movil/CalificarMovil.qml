import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Profesor: actividades de una materia y curso; tocar una abre sus entregas. */
Item {
    id: root
    property var asignaciones: []
    property var actividades: []

    ApiRequests { id: requests }
    function asignacion() { return combo.currentIndex >= 0 && combo.currentIndex < asignaciones.length ? asignaciones[combo.currentIndex] : null }
    function cargar() {
        const a = asignacion()
        if (!a) return
        requests.get("/actividades?materiaId=" + a.materiaId + "&cursoId=" + a.cursoId, d => {
            actividades = (d || []).filter(x => x.activa !== false)
                                   .sort((x, y) => (y.fechaEntrega || "").localeCompare(x.fechaEntrega || ""))
        }, m => toastGlobal.mostrar(m, "error"))
    }
    Component.onCompleted: requests.get("/profesor/asignaciones", d => {
        asignaciones = d || []
        if (asignaciones.length > 0) { combo.currentIndex = 0; cargar() }
    })

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS
        RowLayout {
            Layout.fillWidth: true
            ComboBox { id: combo; Layout.fillWidth: true; model: root.asignaciones; textRole: "nombre"; onActivated: root.cargar() }
            ToolButton { text: "↻"; font.pixelSize: 20; onClicked: root.cargar() }
        }
        ListView {
            id: lista
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingS
            model: root.actividades
            delegate: ItemDelegate {
                id: fila
                required property var modelData
                width: ListView.view.width
                padding: Theme.spacingM
                background: Rectangle { radius: Theme.radiusM; color: fila.pressed ? Theme.surfaceAlt : Theme.surface; border.color: Theme.border }
                onClicked: stackView.push(Qt.resolvedUrl("EntregasMovil.qml"), { actividad: fila.modelData })
                contentItem: RowLayout {
                    spacing: Theme.spacingS
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: fila.modelData.titulo; font.weight: Font.DemiBold; color: Theme.textPrimary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        Label { text: String(fila.modelData.tipo).toUpperCase() + " · " + qsTr("entrega %1").arg(fila.modelData.fechaEntrega); color: Theme.textMuted; font.pixelSize: Theme.fontCaption }
                    }
                    Label { text: "›"; font.pixelSize: 22; color: Theme.textMuted }
                }
            }
            Label {
                anchors.centerIn: parent
                visible: lista.count === 0 && requests.enCurso === 0
                color: Theme.textMuted
                text: qsTr("No hay actividades")
            }
        }
    }
}
