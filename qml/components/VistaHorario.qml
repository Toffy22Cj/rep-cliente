import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

/*
 * Horario semanal. En pantallas anchas, una columna por día; en el teléfono, una lista
 * por día. Resalta la clase en curso y la de hoy.
 *   VistaHorario { bloques: [...]; detalle: "curso" | "profesor" | "ambos"; onBloqueElegido: b => … }
 */
Item {
    id: root
    property var bloques: []
    property string detalle: "profesor"
    property bool soloHoy: false
    signal bloqueElegido(var bloque)

    // Día actual (1 = lunes … 7 = domingo) y minutos del día; se actualiza cada minuto
    property int hoy: ((new Date().getDay() + 6) % 7) + 1
    property int minutoActual: new Date().getHours() * 60 + new Date().getMinutes()
    Timer {
        interval: 60000; repeat: true; running: true
        onTriggered: { root.hoy = ((new Date().getDay() + 6) % 7) + 1; root.minutoActual = new Date().getHours() * 60 + new Date().getMinutes() }
    }

    function minutos(hhmm) { const p = String(hhmm).split(":"); return parseInt(p[0]) * 60 + parseInt(p[1]) }
    function enCurso(b) { return b.dia === hoy && minutos(b.horaInicio) <= minutoActual && minutoActual < minutos(b.horaFin) }

    readonly property var nombresDia: ["", qsTr("Lunes"), qsTr("Martes"), qsTr("Miércoles"), qsTr("Jueves"), qsTr("Viernes"), qsTr("Sábado"), qsTr("Domingo")]
    // Días con clases (lunes a viernes siempre visibles en la vista semanal)
    readonly property var dias: {
        if (soloHoy) return [hoy]
        const conClases = bloques.map(b => b.dia)
        const r = []
        for (let d = 1; d <= 7; d++) if (d <= 5 || conClases.indexOf(d) >= 0) r.push(d)
        return r
    }
    readonly property bool ancho: width > 900 && !soloHoy

    implicitHeight: contenido.implicitHeight

    GridLayout {
        id: contenido
        width: root.width
        columns: root.ancho ? root.dias.length : 1
        columnSpacing: Theme.spacingS
        rowSpacing: Theme.spacingM

        Repeater {
            model: root.dias
            delegate: ColumnLayout {
                id: columna
                required property int modelData
                readonly property var delDia: root.bloques.filter(b => b.dia === modelData)
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: root.ancho ? 1 : -1
                spacing: Theme.spacingXs

                Label {
                    visible: !root.soloHoy
                    text: root.nombresDia[columna.modelData] + (columna.modelData === root.hoy ? " · " + qsTr("hoy") : "")
                    font.weight: Font.DemiBold
                    color: columna.modelData === root.hoy ? Theme.primary : Theme.textSecondary
                }
                Label {
                    visible: columna.delDia.length === 0
                    text: root.soloHoy ? qsTr("Hoy no hay clases") : qsTr("Sin clases")
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontCaption
                }
                Repeater {
                    model: columna.delDia
                    delegate: Rectangle {
                        id: tarjeta
                        required property var modelData
                        readonly property bool ahora: root.enCurso(modelData)
                        Layout.fillWidth: true
                        implicitHeight: info.implicitHeight + 2 * Theme.spacingS
                        radius: Theme.radiusM
                        color: ahora ? Theme.primarySoft : Theme.surface
                        border.color: ahora ? Theme.primary : Theme.border
                        ColumnLayout {
                            id: info
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            spacing: 1
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: tarjeta.modelData.horaInicio + " – " + tarjeta.modelData.horaFin; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary; Layout.fillWidth: true }
                                Label { visible: tarjeta.ahora; text: qsTr("Ahora"); font.pixelSize: Theme.fontCaption; font.weight: Font.Bold; color: Theme.primary }
                            }
                            Label { text: tarjeta.modelData.materia; font.weight: Font.DemiBold; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label {
                                text: [root.detalle !== "profesor" ? tarjeta.modelData.curso : "",
                                       root.detalle !== "curso" ? tarjeta.modelData.profesor : "",
                                       tarjeta.modelData.aula || ""].filter(x => x).join(" · ")
                                visible: text !== ""
                                font.pixelSize: Theme.fontCaption; color: Theme.textMuted; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.bloqueElegido(tarjeta.modelData)
                        }
                    }
                }
            }
        }
    }
}
