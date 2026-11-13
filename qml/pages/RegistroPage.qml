import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Solicitud de cuenta de estudiante (registro público). La cuenta queda inactiva
 * hasta que la administración la activa en Usuarios › Por activar.
 */
Page {
    id: root
    signal volver()
    property var cursos: []
    property string error: ""
    property bool enviando: false
    property bool enviada: false

    background: Rectangle { color: Theme.background }

    ApiRequests { id: requests }

    Component.onCompleted: requests.get("/public/cursos", datos => { cursos = datos || [] },
                                        m => { error = m })

    function enviar() {
        const edad = parseInt(edadField.text)
        const ident = identField.text.trim()
        error = ""
        if (nombreField.text.trim().length < 2 || apellidoField.text.trim().length < 2) error = qsTr("Escriba su nombre y apellido")
        else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoField.text.trim())) error = qsTr("El correo no es válido")
        else if (isNaN(edad) || edad < 5 || edad > 100) error = qsTr("Indique su edad")
        else if (tipoCombo.currentText === "TI" && !/^\d{10}$/.test(ident)) error = qsTr("La tarjeta de identidad tiene 10 dígitos")
        else if (tipoCombo.currentText === "CC" && !/^\d{6,10}$/.test(ident)) error = qsTr("La cédula tiene entre 6 y 10 dígitos")
        else if (cursoCombo.currentIndex < 0) error = qsTr("Seleccione su curso")
        else if (claveField.text.length < 8 || !/[A-Za-z]/.test(claveField.text) || !/\d/.test(claveField.text)) error = qsTr("La contraseña debe tener 8 caracteres o más, con letras y números")
        else if (claveField.text !== confirmarField.text) error = qsTr("La confirmación de la contraseña no coincide")
        if (error !== "") return

        enviando = true
        requests.post("/registro", {
            nombre: nombreField.text.trim(), apellido: apellidoField.text.trim(), correo: correoField.text.trim(),
            identificacion: ident, tipoIdentificacion: tipoCombo.currentText, edad: edad,
            contraseña: claveField.text, rol: "ESTUDIANTE", cursoId: cursos[cursoCombo.currentIndex].id
        }, () => { enviando = false; enviada = true },
           m => { enviando = false; error = m })
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: Math.min(scroll.availableWidth - 2 * Theme.spacingL, 560)
            x: (scroll.availableWidth - width) / 2
            y: Theme.spacingXl
            spacing: Theme.spacingM

            Label { text: qsTr("Solicitar cuenta de estudiante"); font.pixelSize: Theme.fontHeadline; font.weight: Font.Bold; color: Theme.textPrimary }
            Label {
                text: qsTr("Complete sus datos. La administración del colegio revisará la solicitud y activará la cuenta; después podrá entrar con su número de identificación.")
                color: Theme.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true
            }

            Card {
                Layout.fillWidth: true
                visible: root.enviada
                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingS
                    Label { text: "✅ " + qsTr("Solicitud enviada"); font.pixelSize: Theme.fontTitle; font.weight: Font.DemiBold; color: Theme.successDark }
                    Label {
                        text: qsTr("Cuando la administración active su cuenta podrá iniciar sesión con la identificación %1.").arg(identField.text.trim())
                        wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.textPrimary
                    }
                    AppButton { text: qsTr("Volver al inicio de sesión"); onClicked: root.volver() }
                }
            }

            Card {
                Layout.fillWidth: true
                visible: !root.enviada
                GridLayout {
                    anchors.fill: parent
                    columns: root.width > 640 ? 2 : 1
                    columnSpacing: Theme.spacingM
                    rowSpacing: Theme.spacingXs
                    AppTextField { id: nombreField; label: qsTr("Nombre"); Layout.fillWidth: true }
                    AppTextField { id: apellidoField; label: qsTr("Apellido"); Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: Theme.spacingXs
                        Label { text: qsTr("Tipo de documento"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                        ComboBox { id: tipoCombo; Layout.fillWidth: true; model: ["TI", "CC"] }
                    }
                    AppTextField { id: identField; label: qsTr("Número de documento"); Layout.fillWidth: true; field.inputMethodHints: Qt.ImhDigitsOnly }
                    AppTextField { id: correoField; label: qsTr("Correo"); Layout.fillWidth: true }
                    AppTextField { id: edadField; label: qsTr("Edad"); Layout.fillWidth: true; field.validator: IntValidator { bottom: 1; top: 120 } }
                    ColumnLayout {
                        spacing: Theme.spacingXs
                        Layout.fillWidth: true
                        Label { text: qsTr("Curso"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                        ComboBox { id: cursoCombo; Layout.fillWidth: true; model: root.cursos; textRole: "nombre" }
                    }
                    Item { Layout.fillWidth: true }
                    AppTextField { id: claveField; label: qsTr("Contraseña"); echoMode: TextInput.Password; Layout.fillWidth: true }
                    AppTextField { id: confirmarField; label: qsTr("Confirmar contraseña"); echoMode: TextInput.Password; Layout.fillWidth: true }
                }
            }

            Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                visible: !root.enviada
                AppButton { text: qsTr("Cancelar"); variant: "secondary"; onClicked: root.volver() }
                Item { Layout.fillWidth: true }
                AppButton {
                    text: root.enviando ? qsTr("Enviando…") : qsTr("Enviar solicitud")
                    enabled: !root.enviando
                    onClicked: root.enviar()
                }
            }
            Item { Layout.preferredHeight: Theme.spacingL }
        }
    }
}
