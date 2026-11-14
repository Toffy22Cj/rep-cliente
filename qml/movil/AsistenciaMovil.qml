import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Profesor: asistencia de una materia y curso en una fecha. Por defecto todos
 * presentes: solo se marcan las novedades. Sin conexión se guarda en el teléfono y se
 * envía al reconectar.
 */
Item {
    id: root
    property var asignaciones: []
    property date fecha: new Date()
    property bool guardando: false
    property bool existente: false
    property var pendienteAbrir: null

    readonly property var estados: [
        { valor: "PRESENTE", texto: qsTr("Presente"), color: Theme.successDark },
        { valor: "RETARDO", texto: qsTr("Tarde"), color: Theme.warning },
        { valor: "EXCUSA", texto: qsTr("Excusa"), color: Theme.info },
        { valor: "NO_INGRESO", texto: qsTr("Falta"), color: Theme.dangerDark }
    ]

    ListModel { id: filas }
    ApiRequests { id: requests }

    function asignacion() { return combo.currentIndex >= 0 && combo.currentIndex < asignaciones.length ? asignaciones[combo.currentIndex] : null }
    function fechaIso() { return Qt.formatDate(fecha, "yyyy-MM-dd") }
    function ruta(a) { return "/profesor/asistencia?cursoId=" + a.cursoId + "&materiaId=" + a.materiaId + "&fecha=" + fechaIso() }
    function conteo(valor) { let n = 0; for (let i = 0; i < filas.count; i++) if (filas.get(i).estado === valor) n++; return n }
    property int version: 0

    /** Desde el horario: abre la clase tocada en la fecha de hoy. */
    function abrirCon(bloque) {
        const i = asignaciones.findIndex(a => a.id === bloque.asignacionId)
        if (i < 0) { pendienteAbrir = bloque; return }
        combo.currentIndex = i
        fecha = new Date()
        cargar()
    }

    function cargar() {
        const a = asignacion()
        if (!a) return
        filas.clear()
        requests.get(ruta(a), lista => {
            existente = (lista || []).length > 0
            if (existente) {
                for (const r of lista)
                    filas.append({ estudianteId: r.estudiante.id, nombre: (r.estudiante.nombre + " " + (r.estudiante.apellido || "")).trim(),
                                   estado: r.estado, observacion: r.observacion || "" })
                version++
            } else {
                requests.get("/profesor/estudiantes/curso/" + a.cursoId, estudiantes => {
                    for (const e of (estudiantes || []).sort((x, y) => (x.apellido + x.nombre).localeCompare(y.apellido + y.nombre)))
                        filas.append({ estudianteId: e.id, nombre: (e.nombre + " " + (e.apellido || "")).trim(), estado: "PRESENTE", observacion: "" })
                    version++
                }, m => toastGlobal.mostrar(m, "error"))
            }
        }, m => toastGlobal.mostrar(m, "error"))
    }

    function guardar() {
        const a = asignacion()
        if (!a || filas.count === 0) return
        const cuerpo = []
        for (let i = 0; i < filas.count; i++) {
            const f = filas.get(i)
            cuerpo.push({ estudianteId: f.estudianteId, estado: f.estado, tipoExcusa: "", observacion: f.observacion })
        }
        const r = ruta(a)
        const descripcion = qsTr("Asistencia %1 del %2").arg(a.nombre).arg(Qt.formatDate(fecha, "dd/MM"))
        guardando = true
        requests.post(r, cuerpo, () => {
            guardando = false
            existente = true
            toastGlobal.mostrar(qsTr("Asistencia guardada"), "exito")
        }, (mensaje, codigo) => {
            guardando = false
            if (!sincronizacion.enLinea && !codigo) {
                // Sin conexión: queda en el teléfono y se envía sola al volver la red
                sincronizacion.encolarPeticion("POST", r, cuerpo, descripcion)
                toastGlobal.mostrar(qsTr("Sin conexión: la asistencia quedó guardada en el teléfono y se enviará al reconectar"), "info")
            } else {
                toastGlobal.mostrar(mensaje, "error")
            }
        })
    }

    Component.onCompleted: requests.get("/profesor/asignaciones", d => {
        asignaciones = d || []
        if (pendienteAbrir) { const b = pendienteAbrir; pendienteAbrir = null; abrirCon(b) }
        else if (asignaciones.length > 0) { combo.currentIndex = 0; cargar() }
    }, m => toastGlobal.mostrar(m, "error"))

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        ComboBox {
            id: combo
            Layout.fillWidth: true
            model: root.asignaciones
            textRole: "nombre"
            onActivated: root.cargar()
        }
        RowLayout {
            Layout.fillWidth: true
            ToolButton { text: "‹"; font.pixelSize: 22; onClicked: { root.fecha = new Date(root.fecha.getTime() - 86400000); root.cargar() } }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale("es_CO").toString(root.fecha, "ddd d MMM yyyy") + (root.existente ? "  ✔" : "")
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }
            ToolButton { text: "›"; font.pixelSize: 22; onClicked: { root.fecha = new Date(root.fecha.getTime() + 86400000); root.cargar() } }
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontCaption
            color: Theme.textSecondary
            text: { root.version; return qsTr("Presentes %1 · Tarde %2 · Excusa %3 · Faltas %4").arg(root.conteo("PRESENTE")).arg(root.conteo("RETARDO")).arg(root.conteo("EXCUSA")).arg(root.conteo("NO_INGRESO")) }
        }

        ListView {
            id: lista
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingXs
            model: filas
            delegate: Card {
                id: fila
                required property int index
                required property string nombre
                required property string estado
                width: ListView.view.width
                padding: Theme.spacingS
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4
                    Label { text: fila.nombre; font.weight: Font.DemiBold; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: root.estados
                            delegate: Button {
                                required property var modelData
                                readonly property bool elegido: fila.estado === modelData.valor
                                Layout.fillWidth: true
                                implicitHeight: 40
                                text: modelData.texto
                                font.pixelSize: Theme.fontCaption
                                font.weight: elegido ? Font.Bold : Font.Normal
                                Accessible.name: fila.nombre + ": " + modelData.texto
                                background: Rectangle {
                                    radius: Theme.radiusS
                                    color: parent.elegido ? parent.modelData.color : Theme.surfaceAlt
                                }
                                contentItem: Label {
                                    text: parent.text
                                    font: parent.font
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: parent.elegido ? "white" : Theme.textSecondary
                                }
                                onClicked: { filas.setProperty(fila.index, "estado", modelData.valor); root.version++ }
                            }
                        }
                    }
                }
            }
            Label {
                anchors.centerIn: parent
                visible: filas.count === 0 && requests.enCurso === 0
                width: parent.width - 2 * Theme.spacingL
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                text: root.asignaciones.length === 0 ? qsTr("No tiene materias asignadas") : qsTr("Sin estudiantes en este curso")
            }
        }

        AppButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            text: root.guardando ? qsTr("Guardando…") : root.existente ? qsTr("Actualizar asistencia") : qsTr("Guardar asistencia")
            enabled: filas.count > 0 && !root.guardando
            onClicked: root.guardar()
        }
    }
}
