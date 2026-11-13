import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Gestión de usuarios (administrador): alta de estudiantes, profesores y
 * administradores, edición, activación (también de cuentas solicitadas desde el
 * registro público), cambio de curso de un estudiante y eliminación.
 * Antes no se podían crear usuarios y "Editar" reactivaba la cuenta y guardaba el
 * nombre completo en el campo nombre.
 */
Page {
    id: root
    property var usuarios: []
    property var cursos: []
    property string rolFiltro: ""
    property string busqueda: ""

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: qsTr("Usuarios")
        subtitle: qsTr("%n usuario(s)", "", root.usuarios.length)
                  + (root.pendientes > 0 ? " · " + qsTr("%n pendiente(s) de activación", "", root.pendientes) : "")
        AppButton {
            text: qsTr("+ Nuevo usuario")
            enabled: sincronizacion.enLinea
            onClicked: alta.abrir()
        }
    }

    ApiRequests { id: requests }
    Toast { id: toast }

    readonly property int pendientes: usuarios.filter(u => u.rol === "ESTUDIANTE" && !u.activo).length

    function cargar() {
        requests.get("/admin/usuarios", datos => {
            usuarios = (datos || []).sort((a, b) => (a.apellido + a.nombre).localeCompare(b.apellido + b.nombre))
        }, m => toast.mostrar(m, "error"))
    }

    function visibles() {
        const q = busqueda.trim().toLowerCase()
        return usuarios.filter(u => (rolFiltro === "" || (rolFiltro === "PENDIENTES" ? (u.rol === "ESTUDIANTE" && !u.activo) : u.rol === rolFiltro))
                               && (q === "" || (u.nombre + " " + u.apellido + " " + u.correo + " " + u.identificacion).toLowerCase().indexOf(q) >= 0))
    }

    function rolTexto(r) { return r === "ADMIN" ? qsTr("Administrador") : r === "PROFESOR" ? qsTr("Profesor") : qsTr("Estudiante") }

    function cambiarEstado(u, activo) {
        requests.put("/admin/usuarios/" + u.id + "/estado?activo=" + activo, null, () => {
            toast.mostrar(activo ? qsTr("%1 puede iniciar sesión").arg(u.nombre) : qsTr("Cuenta de %1 desactivada").arg(u.nombre), "exito")
            cargar()
        }, m => { toast.mostrar(m, "error"); cargar() })
    }

    Component.onCompleted: {
        cargar()
        requests.get("/admin/cursos", datos => { cursos = datos || [] })
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS
            Repeater {
                model: [
                    { valor: "", texto: qsTr("Todos") },
                    { valor: "ESTUDIANTE", texto: qsTr("Estudiantes") },
                    { valor: "PROFESOR", texto: qsTr("Profesores") },
                    { valor: "ADMIN", texto: qsTr("Administradores") },
                    { valor: "PENDIENTES", texto: qsTr("Por activar") }
                ]
                delegate: AppButton {
                    required property var modelData
                    text: modelData.texto + (modelData.valor === "PENDIENTES" && root.pendientes > 0 ? " (" + root.pendientes + ")" : "")
                    variant: root.rolFiltro === modelData.valor ? "primary" : "secondary"
                    onClicked: root.rolFiltro = modelData.valor
                }
            }
            Item { Layout.fillWidth: true }
            AppTextField {
                Layout.preferredWidth: 280
                placeholderText: qsTr("Buscar por nombre, correo o identificación…")
                onTextChanged: root.busqueda = text
            }
        }

        EmptyState {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: lista.count === 0 && requests.enCurso === 0
            title: qsTr("No hay usuarios con ese filtro")
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
                id: fila
                required property var modelData
                width: ListView.view.width
                padding: Theme.spacingM

                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM
                    Avatar {
                        text: (fila.modelData.nombre.charAt(0) + fila.modelData.apellido.charAt(0)).toUpperCase()
                        tint: fila.modelData.rol === "ADMIN" ? Theme.danger : fila.modelData.rol === "PROFESOR" ? Theme.primary : Theme.success
                        Layout.preferredWidth: 40
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: fila.modelData.nombre + " " + fila.modelData.apellido; font.weight: Font.DemiBold; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label {
                            text: fila.modelData.tipoIdentificacion + " " + fila.modelData.identificacion + " · " + fila.modelData.correo
                            color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                    Badge {
                        text: root.rolTexto(fila.modelData.rol) + (fila.modelData.rol === "ESTUDIANTE" ? " · " + fila.modelData.cursoNombre : "")
                        tint: fila.modelData.rol === "ADMIN" ? Theme.dangerDark : fila.modelData.rol === "PROFESOR" ? Theme.primary : Theme.successDark
                        softTint: fila.modelData.rol === "ADMIN" ? Theme.dangerSoft : fila.modelData.rol === "PROFESOR" ? Theme.primarySoft : Theme.successSoft
                    }
                    Switch {
                        checked: fila.modelData.activo
                        text: checked ? qsTr("Activo") : qsTr("Inactivo")
                        enabled: sincronizacion.enLinea
                        Layout.preferredWidth: 130
                        onToggled: root.cambiarEstado(fila.modelData, checked)
                    }
                    ToolButton {
                        text: "⋯"
                        font.pixelSize: Theme.fontTitle
                        Accessible.name: qsTr("Más acciones")
                        enabled: sincronizacion.enLinea
                        onClicked: menu.popup()
                        Menu {
                            id: menu
                            MenuItem { text: qsTr("Editar datos"); onTriggered: edicion.abrir(fila.modelData) }
                            MenuItem {
                                text: qsTr("Cambiar de curso")
                                visible: fila.modelData.rol === "ESTUDIANTE"
                                height: visible ? implicitHeight : 0
                                onTriggered: cambioCurso.abrir(fila.modelData)
                            }
                            MenuSeparator {}
                            MenuItem { text: qsTr("Eliminar…"); onTriggered: borrar.abrir(fila.modelData) }
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------ alta
    Dialog {
        id: alta
        property string errorTexto: ""
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 560)
        title: qsTr("Nuevo usuario")
        standardButtons: Dialog.Save | Dialog.Cancel
        readonly property string rol: ["ESTUDIANTE", "PROFESOR", "ADMIN"][rolCombo.currentIndex]

        function abrir() {
            errorTexto = ""
            for (const f of [aNombre, aApellido, aCorreo, aIdent, aClave, aEdad]) f.text = ""
            rolCombo.currentIndex = 0
            tipoCombo.currentIndex = 1
            open()
        }

        onAccepted: {
            const edad = parseInt(aEdad.text)
            let problema = ""
            if (aNombre.text.trim().length < 2 || aApellido.text.trim().length < 2) problema = qsTr("Nombre y apellido son obligatorios")
            else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(aCorreo.text.trim())) problema = qsTr("El correo no es válido")
            else if (!/^\d{5,20}$/.test(aIdent.text.trim())) problema = qsTr("La identificación debe tener entre 5 y 20 dígitos")
            else if (aClave.text.length < 8 || !/[A-Za-z]/.test(aClave.text) || !/\d/.test(aClave.text)) problema = qsTr("La contraseña inicial debe tener 8 caracteres o más, con letras y números")
            else if (isNaN(edad) || edad < 5 || edad > 100) problema = qsTr("Indique una edad válida")
            else if (rol === "ESTUDIANTE" && cursoAlta.currentIndex < 0) problema = qsTr("Seleccione el curso del estudiante")
            if (problema !== "") { errorTexto = problema; open(); return }

            const cuerpo = {
                nombre: aNombre.text.trim(), apellido: aApellido.text.trim(), correo: aCorreo.text.trim(),
                identificacion: aIdent.text.trim(), tipoIdentificacion: tipoCombo.currentText,
                contraseña: aClave.text, rol: rol, activo: true, edad: edad
            }
            if (rol === "ESTUDIANTE") cuerpo.cursoId = root.cursos[cursoAlta.currentIndex].id
            requests.post("/admin/usuarios", cuerpo, () => {
                toast.mostrar(qsTr("Usuario creado. Entréguele su identificación y la contraseña inicial."), "exito")
                root.cargar()
            }, m => { errorTexto = m; open() })
        }

        GridLayout {
            anchors.fill: parent
            columns: 2
            columnSpacing: Theme.spacingM
            rowSpacing: Theme.spacingXs
            ColumnLayout {
                spacing: Theme.spacingXs
                Label { text: qsTr("Rol"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                ComboBox { id: rolCombo; Layout.fillWidth: true; model: [qsTr("Estudiante"), qsTr("Profesor"), qsTr("Administrador")] }
            }
            ColumnLayout {
                spacing: Theme.spacingXs
                visible: alta.rol === "ESTUDIANTE"
                Label { text: qsTr("Curso"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                ComboBox { id: cursoAlta; Layout.fillWidth: true; model: root.cursos; textRole: "nombreCompleto" }
            }
            Item { visible: alta.rol !== "ESTUDIANTE"; Layout.fillWidth: true }
            AppTextField { id: aNombre; label: qsTr("Nombre"); Layout.fillWidth: true }
            AppTextField { id: aApellido; label: qsTr("Apellido"); Layout.fillWidth: true }
            ColumnLayout {
                spacing: Theme.spacingXs
                Label { text: qsTr("Tipo de documento"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                ComboBox { id: tipoCombo; Layout.fillWidth: true; model: ["CC", "TI"] }
            }
            AppTextField { id: aIdent; label: qsTr("Número de identificación"); Layout.fillWidth: true; field.inputMethodHints: Qt.ImhDigitsOnly }
            AppTextField { id: aCorreo; label: qsTr("Correo"); Layout.fillWidth: true }
            AppTextField { id: aEdad; label: qsTr("Edad"); Layout.fillWidth: true; field.validator: IntValidator { bottom: 1; top: 120 } }
            AppTextField { id: aClave; label: qsTr("Contraseña inicial"); echoMode: TextInput.Password; Layout.fillWidth: true; Layout.columnSpan: 2 }
            Label { visible: alta.errorTexto !== ""; text: alta.errorTexto; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.columnSpan: 2 }
        }
    }

    // ------------------------------------------------ edición
    Dialog {
        id: edicion
        property var usuario: null
        property string errorTexto: ""
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 480)
        title: usuario ? qsTr("Editar %1").arg(usuario.nombre + " " + usuario.apellido) : ""
        standardButtons: Dialog.Save | Dialog.Cancel

        function abrir(u) {
            usuario = u; errorTexto = ""
            eNombre.text = u.nombre; eApellido.text = u.apellido; eCorreo.text = u.correo; eClave.text = ""
            open()
        }

        onAccepted: {
            const clave = eClave.text
            if (clave !== "" && (clave.length < 8 || !/[A-Za-z]/.test(clave) || !/\d/.test(clave))) {
                errorTexto = qsTr("La nueva contraseña debe tener 8 caracteres o más, con letras y números"); open(); return
            }
            // Solo se envían los campos que se editan: el rol y el estado no se tocan aquí
            const cuerpo = { nombre: eNombre.text.trim(), apellido: eApellido.text.trim(), correo: eCorreo.text.trim() }
            if (clave !== "") cuerpo["contraseña"] = clave
            requests.put("/admin/usuarios/" + usuario.id, cuerpo, () => {
                toast.mostrar(clave !== "" ? qsTr("Datos y contraseña actualizados") : qsTr("Datos actualizados"), "exito")
                root.cargar()
            }, m => { errorTexto = m; open() })
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingXs
            AppTextField { id: eNombre; label: qsTr("Nombre"); Layout.fillWidth: true }
            AppTextField { id: eApellido; label: qsTr("Apellido"); Layout.fillWidth: true }
            AppTextField { id: eCorreo; label: qsTr("Correo"); Layout.fillWidth: true }
            AppTextField { id: eClave; label: qsTr("Nueva contraseña (dejar vacío para no cambiarla)"); echoMode: TextInput.Password; Layout.fillWidth: true }
            Label { visible: edicion.errorTexto !== ""; text: edicion.errorTexto; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
    }

    // ------------------------------------------------ cambio de curso
    Dialog {
        id: cambioCurso
        property var usuario: null
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 420)
        title: qsTr("Cambiar de curso")
        standardButtons: Dialog.Save | Dialog.Cancel
        function abrir(u) {
            usuario = u
            cursoCombo.currentIndex = Math.max(0, root.cursos.findIndex(c => c.nombreCompleto === u.cursoNombre))
            open()
        }
        onAccepted: requests.put("/admin/estudiantes/" + usuario.id + "/curso?cursoId=" + root.cursos[cursoCombo.currentIndex].id, null, () => {
            toast.mostrar(qsTr("%1 ahora está en %2").arg(usuario.nombre).arg(cursoCombo.currentText), "exito")
            root.cargar()
        }, m => toast.mostrar(m, "error"))
        ColumnLayout {
            anchors.fill: parent
            Label { text: cambioCurso.usuario ? qsTr("Curso actual: %1").arg(cambioCurso.usuario.cursoNombre) : ""; color: Theme.textSecondary }
            ComboBox { id: cursoCombo; Layout.fillWidth: true; model: root.cursos; textRole: "nombreCompleto" }
            Label {
                text: qsTr("Desde ese momento verá las actividades del nuevo curso.")
                color: Theme.textMuted; font.pixelSize: Theme.fontCaption; wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
        }
    }

    // ------------------------------------------------ eliminación
    Dialog {
        id: borrar
        property var usuario: null
        function abrir(u) { usuario = u; open() }
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 440)
        title: qsTr("Eliminar usuario")
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: requests.eliminar("/admin/usuarios/" + usuario.id, () => {
            toast.mostrar(qsTr("Usuario eliminado"), "exito"); root.cargar()
        }, m => toast.mostrar(m, "error"))
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.textPrimary
            text: borrar.usuario ? qsTr("¿Eliminar a %1 %2? Si tiene entregas, notas o asignaciones es mejor desactivarlo.")
                                   .arg(borrar.usuario.nombre).arg(borrar.usuario.apellido) : ""
        }
    }
}
