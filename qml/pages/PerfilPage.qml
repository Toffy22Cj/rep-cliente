import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Mi perfil (todos los roles): datos personales, cambio de contraseña y datos
 * guardados para uso sin conexión.
 */
Page {
    id: root
    property var perfil: null
    property string errorDatos: ""
    property string errorClave: ""
    property bool guardandoDatos: false
    property bool guardandoClave: false
    /** Contraseña provisional: no se puede salir hasta cambiarla. */
    property bool obligatorio: false

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: root.obligatorio ? qsTr("Cambie su contraseña") : qsTr("Mi perfil")
        subtitle: root.obligatorio ? qsTr("Su contraseña es provisional") : qsTr("Datos personales y seguridad de la cuenta")
        showBack: !root.obligatorio
    }

    ApiRequests { id: requests }
    Toast { id: toast }

    readonly property var sexos: [
        { valor: "", texto: qsTr("Sin especificar") },
        { valor: "FEMENINO", texto: qsTr("Femenino") },
        { valor: "MASCULINO", texto: qsTr("Masculino") },
        { valor: "OTRO", texto: qsTr("Otro") }
    ]

    function rolTexto(r) {
        return r === "ADMIN" ? qsTr("Administrador") : r === "PROFESOR" ? qsTr("Profesor") : qsTr("Estudiante")
    }

    function cargar() {
        requests.get("/perfil", datos => {
            perfil = datos
            nombreField.text = datos.nombre
            apellidoField.text = datos.apellido
            correoField.text = datos.correo
            const i = sexos.findIndex(s => s.valor === (datos.sexo || ""))
            sexoCombo.currentIndex = i < 0 ? 0 : i
        }, mensaje => { errorDatos = mensaje })
    }

    function guardarDatos() {
        errorDatos = ""
        if (nombreField.text.trim().length < 2 || apellidoField.text.trim().length < 2) {
            errorDatos = qsTr("Nombre y apellido deben tener al menos 2 caracteres"); return
        }
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoField.text.trim())) {
            errorDatos = qsTr("El correo no es válido"); return
        }
        guardandoDatos = true
        const sexo = sexos[sexoCombo.currentIndex].valor
        requests.put("/perfil", {
            nombre: nombreField.text.trim(),
            apellido: apellidoField.text.trim(),
            correo: correoField.text.trim(),
            sexo: sexo === "" ? null : sexo
        }, datos => {
            guardandoDatos = false
            perfil = datos
            sessionManager.actualizarDatos(datos.nombre, datos.apellido, datos.correo)
            toast.mostrar(qsTr("Datos actualizados"), "exito")
        }, mensaje => { guardandoDatos = false; errorDatos = mensaje })
    }

    // Requisitos visibles mientras se escribe (los mismos que valida el servidor)
    readonly property bool claveLargo: nuevaField.text.length >= 8
    readonly property bool claveMixta: /[A-Za-zÁÉÍÓÚáéíóúÑñ]/.test(nuevaField.text) && /\d/.test(nuevaField.text)
    readonly property bool claveCoincide: nuevaField.text !== "" && nuevaField.text === confirmarField.text

    function cambiarClave() {
        errorClave = ""
        if (actualField.text === "") { errorClave = qsTr("Escriba su contraseña actual"); return }
        if (!claveLargo || !claveMixta) { errorClave = qsTr("La nueva contraseña no cumple los requisitos"); return }
        if (!claveCoincide) { errorClave = qsTr("La confirmación no coincide"); return }
        guardandoClave = true
        requests.put("/perfil/contrasena", { actual: actualField.text, nueva: nuevaField.text }, datos => {
            guardandoClave = false
            // El servidor invalida los tokens anteriores y entrega uno nuevo
            sessionManager.actualizarToken(datos.token)
            sessionManager.contrasenaCambiada()
            actualField.text = ""; nuevaField.text = ""; confirmarField.text = ""
            toast.mostrar(qsTr("Contraseña actualizada. Las sesiones abiertas en otros equipos se cerraron."), "exito")
        }, mensaje => { guardandoClave = false; errorClave = mensaje })
    }

    Component.onCompleted: cargar()

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: Math.min(scroll.availableWidth - 2 * Theme.spacingXl, 820)
            x: (scroll.availableWidth - width) / 2
            y: Theme.spacingL
            spacing: Theme.spacingM

            Rectangle {
                visible: root.obligatorio
                Layout.fillWidth: true
                implicitHeight: avisoObligatorio.implicitHeight + 2 * Theme.spacingM
                radius: Theme.radiusM
                color: Theme.warningSoft
                border.color: Theme.warning
                Label {
                    id: avisoObligatorio
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    wrapMode: Text.WordWrap
                    color: Theme.textPrimary
                    text: qsTr("⚠ Está usando una contraseña provisional. Defina una contraseña propia en «Cambiar contraseña» para continuar.")
                }
            }

            // ------------------------------------------------ cabecera
            Card {
                Layout.fillWidth: true
                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM
                    Avatar { text: sessionManager.userInitials; size: 64; Layout.preferredWidth: 64; Layout.fillWidth: false }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: root.perfil ? root.perfil.nombre + " " + root.perfil.apellido : sessionManager.userFullName
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                            Layout.fillWidth: true
                        }
                        Label {
                            Layout.fillWidth: true
                            text: root.perfil ? root.rolTexto(root.perfil.rol)
                                                + (root.perfil.curso ? " · " + qsTr("Curso %1").arg(root.perfil.curso) : "")
                                              : ""
                            color: Theme.textSecondary
                        }
                        Label {
                            Layout.fillWidth: true
                            text: root.perfil ? (root.perfil.tipoIdentificacion || "") + " " + root.perfil.identificacion : ""
                            color: Theme.textMuted
                            font.pixelSize: Theme.fontCaption
                        }
                    }
                }
            }

            // ------------------------------------------------ asignaciones del profesor
            Card {
                Layout.fillWidth: true
                visible: root.perfil && root.perfil.asignaciones && root.perfil.asignaciones.length > 0
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: qsTr("Mis asignaciones"); font.weight: Font.DemiBold; color: Theme.textPrimary }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.spacingS
                        Repeater {
                            model: root.perfil ? root.perfil.asignaciones : []
                            delegate: Badge { required property var modelData; text: modelData }
                        }
                    }
                }
            }

            // ------------------------------------------------ datos personales
            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingS
                    Label { text: qsTr("Datos personales"); font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; color: Theme.textPrimary }
                    Label {
                        text: qsTr("La identificación, el rol, la edad y el curso solo los puede cambiar la administración.")
                        color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.width > 760 ? 2 : 1
                        columnSpacing: Theme.spacingM
                        AppTextField { id: nombreField; label: qsTr("Nombre"); Layout.fillWidth: true }
                        AppTextField { id: apellidoField; label: qsTr("Apellido"); Layout.fillWidth: true }
                        AppTextField { id: correoField; label: qsTr("Correo"); Layout.fillWidth: true }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXs
                            Label { text: qsTr("Sexo"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption; font.weight: Font.Medium }
                            ComboBox { id: sexoCombo; Layout.fillWidth: true; model: root.sexos; textRole: "texto" }
                        }
                    }
                    Label { visible: root.errorDatos !== ""; text: root.errorDatos; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    AppButton {
                        Layout.alignment: Qt.AlignRight
                        text: root.guardandoDatos ? qsTr("Guardando…") : qsTr("Guardar cambios")
                        enabled: !root.guardandoDatos && sincronizacion.enLinea
                        onClicked: root.guardarDatos()
                    }
                }
            }

            // ------------------------------------------------ contraseña
            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingS
                    Label { text: qsTr("Cambiar contraseña"); font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; color: Theme.textPrimary }
                    AppTextField { id: actualField; label: qsTr("Contraseña actual"); echoMode: TextInput.Password; Layout.fillWidth: true }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.width > 760 ? 2 : 1
                        columnSpacing: Theme.spacingM
                        AppTextField { id: nuevaField; label: qsTr("Nueva contraseña"); echoMode: TextInput.Password; Layout.fillWidth: true }
                        AppTextField { id: confirmarField; label: qsTr("Confirmar nueva contraseña"); echoMode: TextInput.Password; Layout.fillWidth: true }
                    }
                    Column {
                        spacing: 2
                        Repeater {
                            model: [
                                { ok: root.claveLargo, texto: qsTr("Al menos 8 caracteres") },
                                { ok: root.claveMixta, texto: qsTr("Letras y números") },
                                { ok: root.claveCoincide, texto: qsTr("La confirmación coincide") }
                            ]
                            delegate: Label {
                                required property var modelData
                                text: (modelData.ok ? "✔ " : "○ ") + modelData.texto
                                color: modelData.ok ? Theme.successDark : Theme.textMuted
                                font.pixelSize: Theme.fontCaption
                            }
                        }
                    }
                    Label { visible: root.errorClave !== ""; text: root.errorClave; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    AppButton {
                        Layout.alignment: Qt.AlignRight
                        text: root.guardandoClave ? qsTr("Actualizando…") : qsTr("Actualizar contraseña")
                        enabled: !root.guardandoClave && sincronizacion.enLinea
                        onClicked: root.cambiarClave()
                    }
                }
            }

            // ------------------------------------------------ datos sin conexión
            Card {
                Layout.fillWidth: true
                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: qsTr("Datos guardados para uso sin conexión"); font.weight: Font.DemiBold; color: Theme.textPrimary }
                        Label {
                            id: espacioLabel
                            text: qsTr("Ocupan %1 en este equipo. Bórrelos si comparte el computador.").arg(api.espacioSinConexion())
                            color: Theme.textSecondary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                    AppButton {
                        text: qsTr("Borrar")
                        variant: "secondary"
                        onClicked: {
                            api.borrarDatosSinConexion()
                            espacioLabel.text = qsTr("Ocupan %1 en este equipo. Bórrelos si comparte el computador.").arg(api.espacioSinConexion())
                            toast.mostrar(qsTr("Datos sin conexión borrados"), "exito")
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.spacingL }
        }
    }
}
