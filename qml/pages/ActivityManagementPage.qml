import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Gestión de actividades del profesor por materia y curso: crear, editar, publicar u
 * ocultar, duplicar, eliminar, ver estadísticas, editar preguntas y calificar.
 * Antes el curso estaba fijo en 1 y "Editar" no guardaba los cambios.
 */
Page {
    id: root
    property bool createNew: false
    property var asignaciones: []
    property var actividades: []
    property string filtro: ""
    property string error: ""

    readonly property var tipos: ["EXAMEN", "QUIZ", "TALLER"]

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: qsTr("Actividades")
        subtitle: qsTr("%n actividad(es)", "", root.actividades.length)
        AppButton {
            text: qsTr("+ Nueva actividad")
            enabled: root.asignacionActual() !== null && sincronizacion.enLinea
            onClicked: formulario.abrir(null)
        }
    }

    ApiRequests { id: requests }
    Toast { id: toast }

    function asignacionActual() {
        return asignacionCombo.currentIndex >= 0 && asignacionCombo.currentIndex < asignaciones.length
               ? asignaciones[asignacionCombo.currentIndex] : null
    }

    function cargar() {
        const a = asignacionActual()
        if (!a) return
        requests.get("/actividades?materiaId=" + a.materiaId + "&cursoId=" + a.cursoId, datos => {
            actividades = (datos || []).sort((x, y) => (y.fechaEntrega || "").localeCompare(x.fechaEntrega || ""))
            error = ""
        }, mensaje => { error = mensaje })
    }

    function visibles() {
        const f = filtro.trim().toLowerCase()
        return f === "" ? actividades : actividades.filter(a => a.titulo.toLowerCase().indexOf(f) >= 0)
    }

    function fallo(mensaje) { toast.mostrar(mensaje, "error") }

    function clonar(a) {
        requests.post("/actividades/" + a.id + "/clonar", {}, nueva => {
            toast.mostrar(qsTr("Se creó «%1» con sus preguntas").arg(nueva.titulo), "exito")
            cargar()
        }, fallo)
    }

    function cambiarEstado(a) {
        requests.put("/actividades/" + a.id + "/estado?activa=" + (a.activa === false), null, () => {
            toast.mostrar(a.activa === false ? qsTr("Actividad publicada") : qsTr("Actividad oculta a los estudiantes"), "exito")
            cargar()
        }, fallo)
    }

    function cambiarRespuestas(a) {
        const mostrar = a.mostrarRespuestas === false
        requests.put("/actividades/" + a.id, {
            titulo: a.titulo, tipo: String(a.tipo).toUpperCase(), descripcion: a.descripcion || "",
            fechaEntrega: a.fechaEntrega, duracionMinutos: a.duracionMinutos,
            materiaId: a.materiaId, cursoId: a.cursoId, mostrarRespuestas: mostrar
        }, () => {
            toast.mostrar(mostrar ? qsTr("Los estudiantes verán las respuestas correctas")
                                  : qsTr("Los estudiantes solo verán su nota"), "exito")
            cargar()
        }, fallo)
    }

    function eliminar(a) {
        requests.eliminar("/actividades/" + a.id, () => {
            toast.mostrar(qsTr("Actividad eliminada"), "exito")
            cargar()
        }, fallo)
    }

    Component.onCompleted: requests.get("/profesor/asignaciones", datos => {
        asignaciones = datos || []
        if (asignaciones.length > 0) {
            asignacionCombo.currentIndex = 0
            cargar()
            if (createNew) formulario.abrir(null)
        }
    }, mensaje => { error = mensaje })

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM
            Label { text: qsTr("Materia y curso:"); color: Theme.textSecondary }
            ComboBox {
                id: asignacionCombo
                Layout.preferredWidth: 300
                model: root.asignaciones
                textRole: "nombre"
                onActivated: root.cargar()
            }
            Item { Layout.fillWidth: true }
            AppTextField {
                Layout.preferredWidth: 260
                placeholderText: qsTr("Buscar por título…")
                onTextChanged: root.filtro = text
            }
        }

        Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }

        EmptyState {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: lista.count === 0 && requests.enCurso === 0
            title: root.asignaciones.length === 0 ? qsTr("No tiene materias asignadas") : qsTr("No hay actividades")
            message: root.asignaciones.length === 0 ? qsTr("Pida al administrador que le asigne materias y cursos.")
                                                    : qsTr("Cree la primera con «Nueva actividad».")
        }

        ListView {
            id: lista
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: count > 0
            clip: true
            spacing: Theme.spacingS
            model: root.visibles()
            ScrollBar.vertical: ScrollBar {}

            delegate: Card {
                id: tarjeta
                required property var modelData
                readonly property bool vencida: modelData.fechaEntrega && new Date(modelData.fechaEntrega + "T23:59:59") < new Date()
                width: ListView.view.width
                padding: Theme.spacingM

                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            spacing: Theme.spacingS
                            Label { text: tarjeta.modelData.titulo; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; color: Theme.textPrimary; elide: Text.ElideRight; Layout.maximumWidth: 420 }
                            Badge { text: String(tarjeta.modelData.tipo).toUpperCase() }
                            Badge {
                                visible: tarjeta.modelData.mostrarRespuestas === false
                                text: qsTr("Respuestas ocultas")
                                tint: Theme.textSecondary; softTint: Theme.surfaceAlt
                            }
                            Badge {
                                visible: tarjeta.modelData.activa === false
                                text: qsTr("Oculta")
                                tint: Theme.textSecondary; softTint: Theme.surfaceAlt
                            }
                            Badge {
                                visible: tarjeta.vencida && tarjeta.modelData.activa !== false
                                text: qsTr("Cerrada")
                                tint: Theme.dangerDark; softTint: Theme.dangerSoft
                            }
                        }
                        Label {
                            text: qsTr("Entrega %1 · %2 min").arg(tarjeta.modelData.fechaEntrega).arg(tarjeta.modelData.duracionMinutos)
                                  + (tarjeta.modelData.descripcion ? " · " + tarjeta.modelData.descripcion : "")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    AppButton {
                        text: qsTr("Preguntas")
                        variant: "secondary"
                        onClicked: stackView.push("QuestionEditorPage.qml", { actividadId: tarjeta.modelData.id, actividadTitulo: tarjeta.modelData.titulo })
                    }
                    AppButton {
                        text: qsTr("Calificar")
                        variant: "secondary"
                        onClicked: stackView.push("GradingPage.qml", { actividadId: tarjeta.modelData.id, actividadTitulo: tarjeta.modelData.titulo })
                    }
                    ToolButton {
                        text: "⋯"
                        font.pixelSize: Theme.fontTitle
                        Accessible.name: qsTr("Más acciones")
                        enabled: sincronizacion.enLinea
                        onClicked: menu.popup()
                        Menu {
                            id: menu
                            MenuItem { text: qsTr("Estadísticas"); onTriggered: estadisticas.abrir(tarjeta.modelData) }
                            MenuItem { text: qsTr("Editar datos"); onTriggered: formulario.abrir(tarjeta.modelData) }
                            MenuItem { text: qsTr("Duplicar con preguntas"); onTriggered: root.clonar(tarjeta.modelData) }
                            MenuItem {
                                text: tarjeta.modelData.mostrarRespuestas === false ? qsTr("Mostrar respuestas correctas al entregar")
                                                                                     : qsTr("No mostrar respuestas correctas")
                                onTriggered: root.cambiarRespuestas(tarjeta.modelData)
                            }
                            MenuItem {
                                text: tarjeta.modelData.activa === false ? qsTr("Publicar a los estudiantes") : qsTr("Ocultar a los estudiantes")
                                onTriggered: root.cambiarEstado(tarjeta.modelData)
                            }
                            MenuSeparator {}
                            MenuItem { text: qsTr("Eliminar…"); onTriggered: confirmar.abrir(tarjeta.modelData) }
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------ crear / editar
    Dialog {
        id: formulario
        property var actividad: null
        property string errorTexto: ""
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 520)
        title: actividad ? qsTr("Editar actividad") : qsTr("Nueva actividad")
        standardButtons: Dialog.Save | Dialog.Cancel

        function manana() { const d = new Date(); d.setDate(d.getDate() + 7); return Qt.formatDate(d, "yyyy-MM-dd") }

        function abrir(a) {
            actividad = a
            errorTexto = ""
            tituloField.text = a ? a.titulo : ""
            tipoCombo.currentIndex = a ? Math.max(0, root.tipos.indexOf(String(a.tipo).toUpperCase())) : 0
            descField.text = a ? (a.descripcion || "") : ""
            fechaField.text = a ? a.fechaEntrega : manana()
            durField.text = a ? String(a.duracionMinutos) : "60"
            mostrarCheck.checked = a ? a.mostrarRespuestas !== false : true
            open()
        }

        onAccepted: {
            const a = root.asignacionActual()
            const fecha = fechaField.text.trim()
            const duracion = parseInt(durField.text)
            let problema = ""
            if (tituloField.text.trim().length < 3) problema = qsTr("El título debe tener al menos 3 caracteres")
            else if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha) || isNaN(new Date(fecha).getTime())) problema = qsTr("La fecha debe tener el formato AAAA-MM-DD")
            else if (isNaN(duracion) || duracion <= 0) problema = qsTr("La duración debe ser mayor a 0 minutos")
            if (problema !== "") { errorTexto = problema; open(); return }

            const cuerpo = {
                titulo: tituloField.text.trim(), tipo: root.tipos[tipoCombo.currentIndex],
                descripcion: descField.text.trim(), fechaEntrega: fecha, duracionMinutos: duracion,
                materiaId: actividad ? actividad.materiaId : a.materiaId,
                cursoId: actividad ? actividad.cursoId : a.cursoId,
                mostrarRespuestas: mostrarCheck.checked
            }
            const editando = actividad !== null
            const listo = () => { toast.mostrar(editando ? qsTr("Actividad actualizada") : qsTr("Actividad creada"), "exito"); root.cargar() }
            const fallo = mensaje => { errorTexto = mensaje; open() }
            if (editando) requests.put("/actividades/" + actividad.id, cuerpo, listo, fallo)
            else requests.post("/actividades", cuerpo, listo, fallo)
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingS
            AppTextField { id: tituloField; label: qsTr("Título"); Layout.fillWidth: true }
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM
                ColumnLayout {
                    spacing: Theme.spacingXs
                    Label { text: qsTr("Tipo"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.Medium }
                    ComboBox { id: tipoCombo; model: root.tipos; Layout.preferredWidth: 150 }
                }
                AppTextField { id: fechaField; label: qsTr("Fecha de entrega (AAAA-MM-DD)"); Layout.fillWidth: true }
                AppTextField { id: durField; label: qsTr("Duración (min)"); Layout.preferredWidth: 110; field.validator: IntValidator { bottom: 1; top: 600 } }
            }
            AppTextField { id: descField; label: qsTr("Descripción o instrucciones"); Layout.fillWidth: true }
            CheckBox {
                id: mostrarCheck
                text: qsTr("Mostrar las respuestas correctas al estudiante después de entregar")
                checked: true
            }
            Label { visible: formulario.errorTexto !== ""; text: formulario.errorTexto; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
    }

    // ------------------------------------------------ confirmar eliminación
    Dialog {
        id: confirmar
        property var actividad: null
        function abrir(a) { actividad = a; open() }
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 440)
        title: qsTr("Eliminar actividad")
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: root.eliminar(actividad)
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.textPrimary
            text: qsTr("¿Eliminar «%1» y sus preguntas? Si algún estudiante ya la empezó no se puede eliminar; en ese caso ocúltela.")
                  .arg(confirmar.actividad ? confirmar.actividad.titulo : "")
        }
    }

    // ------------------------------------------------ estadísticas
    Dialog {
        id: estadisticas
        property var actividad: null
        property var datos: null
        function abrir(a) {
            actividad = a; datos = null; open()
            requests.get("/actividades/" + a.id + "/estadisticas", d => { datos = d }, m => { datos = { error: m } })
        }
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 520)
        title: actividad ? actividad.titulo : ""
        standardButtons: Dialog.Close

        function n(v) { return v === null || v === undefined ? "—" : Number(v).toFixed(1) }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingS
            BusyIndicator { visible: estadisticas.datos === null; running: visible; Layout.alignment: Qt.AlignHCenter }
            Label { visible: !!(estadisticas.datos && estadisticas.datos.error); text: estadisticas.datos && estadisticas.datos.error ? estadisticas.datos.error : ""; color: Theme.danger }
            Repeater {
                model: estadisticas.datos && !estadisticas.datos.error ? [
                    [qsTr("Entregas"), estadisticas.datos.entregasRealizadas + " / " + estadisticas.datos.totalEstudiantes + "  (" + estadisticas.datos.porcentajeEntregas + " %)"],
                    [qsTr("Revisadas por usted"), estadisticas.datos.revisadas],
                    [qsTr("En curso"), estadisticas.datos.enCurso],
                    [qsTr("Sin iniciar"), estadisticas.datos.sinIniciar],
                    [qsTr("Promedio"), estadisticas.n(estadisticas.datos.promedio)],
                    [qsTr("Nota más alta / más baja"), estadisticas.n(estadisticas.datos.notaMaxima) + " / " + estadisticas.n(estadisticas.datos.notaMinima)],
                    [qsTr("Preguntas"), estadisticas.datos.preguntas]
                ] : []
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Label { text: modelData[0]; color: Theme.textSecondary; Layout.fillWidth: true }
                    Label { text: String(modelData[1]); font.weight: Font.DemiBold; color: Theme.textPrimary }
                }
            }
        }
    }
}
