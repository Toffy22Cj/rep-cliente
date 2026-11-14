import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Horario de clases (administrador): por curso, agregar, editar y eliminar clases.
 * El servidor impide cruces del curso y del profesor.
 */
Page {
    id: root
    property var cursos: []
    property var asignaciones: []
    property var bloques: []

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: qsTr("Horario de clases")
        subtitle: root.cursoActual() ? qsTr("Curso %1 · %n clase(s) por semana", "", root.bloques.length).arg(root.cursoActual().nombreCompleto) : ""
        AppButton {
            text: qsTr("+ Agregar clase")
            enabled: root.cursoActual() !== null && sincronizacion.enLinea
            onClicked: formulario.abrir(null)
        }
    }

    ApiRequests { id: requests }
    Toast { id: toast }

    function cursoActual() { return cursoCombo.currentIndex >= 0 && cursoCombo.currentIndex < cursos.length ? cursos[cursoCombo.currentIndex] : null }
    function asignacionesDelCurso() { const c = cursoActual(); return c ? asignaciones.filter(a => a.curso.id === c.id) : [] }
    function nombreAsignacion(a) { return a.materia.nombre + " · " + a.profesor.nombre + " " + a.profesor.apellido }

    function cargar() {
        const c = cursoActual()
        if (!c) return
        requests.get("/admin/horario?cursoId=" + c.id, d => { bloques = d || [] }, m => toast.mostrar(m, "error"))
    }

    Component.onCompleted: {
        requests.get("/admin/asignaciones", d => { asignaciones = d || [] })
        requests.get("/admin/cursos", d => {
            cursos = d || []
            if (cursos.length > 0) { cursoCombo.currentIndex = 0; cargar() }
        })
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: scroll.availableWidth - 2 * Theme.spacingL
            x: Theme.spacingL
            y: Theme.spacingL
            spacing: Theme.spacingM

            RowLayout {
                spacing: Theme.spacingM
                Label { text: qsTr("Curso:"); color: Theme.textSecondary }
                ComboBox { id: cursoCombo; Layout.preferredWidth: 200; model: root.cursos; textRole: "nombreCompleto"; onActivated: root.cargar() }
                Label {
                    text: qsTr("Pulse una clase para editarla o eliminarla.")
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontCaption
                }
            }
            EmptyState {
                Layout.fillWidth: true
                visible: root.cursos.length > 0 && root.bloques.length === 0 && requests.enCurso === 0
                title: qsTr("Este curso aún no tiene horario")
                message: root.asignacionesDelCurso().length === 0 ? qsTr("Primero asigne materias y profesores al curso (Asignaciones).")
                                                                   : qsTr("Agregue las clases con «+ Agregar clase».")
            }
            VistaHorario {
                Layout.fillWidth: true
                visible: root.bloques.length > 0
                bloques: root.bloques
                detalle: "profesor"
                onBloqueElegido: b => formulario.abrir(b)
            }
            Item { Layout.preferredHeight: Theme.spacingL }
        }
    }

    Dialog {
        id: formulario
        property var bloque: null
        property string errorTexto: ""
        readonly property var opciones: root.asignacionesDelCurso()
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 500)
        title: bloque ? qsTr("Editar clase") : qsTr("Agregar clase")
        footer: DialogButtonBox {
            Button { text: qsTr("Guardar"); DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole }
            Button {
                visible: formulario.bloque !== null
                text: qsTr("Eliminar")
                DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole
                onClicked: formulario.eliminar()
            }
            Button { text: qsTr("Cancelar"); DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
        }

        function abrir(b) {
            bloque = b
            errorTexto = ""
            asignacionCombo.currentIndex = b ? Math.max(0, opciones.findIndex(a => a.id === b.asignacionId)) : 0
            diaCombo.currentIndex = b ? b.dia - 1 : 0
            inicioField.text = b ? b.horaInicio : "07:00"
            finField.text = b ? b.horaFin : "08:00"
            aulaField.text = b ? (b.aula || "") : ""
            open()
        }

        function eliminar() {
            requests.eliminar("/admin/horario/" + bloque.id, () => { toast.mostrar(qsTr("Clase eliminada"), "exito"); close(); root.cargar() },
                              m => { errorTexto = m })
        }

        onAccepted: {
            const hora = /^([01]\d|2[0-3]):[0-5]\d$/
            if (asignacionCombo.currentIndex < 0) { errorTexto = qsTr("Seleccione materia y profesor"); open(); return }
            if (!hora.test(inicioField.text.trim()) || !hora.test(finField.text.trim())) { errorTexto = qsTr("Use horas como 07:00"); open(); return }
            const cuerpo = {
                asignacionId: opciones[asignacionCombo.currentIndex].id, dia: diaCombo.currentIndex + 1,
                horaInicio: inicioField.text.trim(), horaFin: finField.text.trim(), aula: aulaField.text.trim()
            }
            const listo = () => { toast.mostrar(qsTr("Horario guardado"), "exito"); root.cargar() }
            const fallo = m => { errorTexto = m; open() }
            if (bloque) requests.put("/admin/horario/" + bloque.id, cuerpo, listo, fallo)
            else requests.post("/admin/horario", cuerpo, listo, fallo)
        }

        GridLayout {
            anchors.fill: parent
            columns: 2
            columnSpacing: Theme.spacingM
            rowSpacing: Theme.spacingXs
            ColumnLayout {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                spacing: Theme.spacingXs
                Label { text: qsTr("Materia y profesor"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                ComboBox {
                    id: asignacionCombo
                    Layout.fillWidth: true
                    model: formulario.opciones.map(a => root.nombreAsignacion(a))
                }
            }
            ColumnLayout {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                spacing: Theme.spacingXs
                Label { text: qsTr("Día"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                ComboBox { id: diaCombo; Layout.fillWidth: true; model: [qsTr("Lunes"), qsTr("Martes"), qsTr("Miércoles"), qsTr("Jueves"), qsTr("Viernes"), qsTr("Sábado"), qsTr("Domingo")] }
            }
            AppTextField { id: inicioField; label: qsTr("Inicio (HH:mm)"); Layout.fillWidth: true }
            AppTextField { id: finField; label: qsTr("Fin (HH:mm)"); Layout.fillWidth: true }
            AppTextField { id: aulaField; label: qsTr("Aula (opcional)"); Layout.fillWidth: true; Layout.columnSpan: 2 }
            Label { visible: formulario.errorTexto !== ""; text: formulario.errorTexto; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.columnSpan: 2 }
        }
    }
}
