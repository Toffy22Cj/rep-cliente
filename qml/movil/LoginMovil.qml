import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Inicio de sesión en el teléfono, con el servidor encontrado en la red. */
Page {
    id: root
    signal loginSuccess()
    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.primary }
            GradientStop { position: 0.45; color: Theme.background }
        }
    }

    readonly property bool puedeEntrar: !loginViewModel.isLoading && identField.text.trim() !== "" && passField.text !== ""
    function entrar() { if (puedeEntrar) loginViewModel.login(identField.text.trim(), passField.text) }

    Connections {
        target: loginViewModel
        function onLoginSuccess(role) { passField.text = ""; root.loginSuccess() }
    }
    // Primera vez: si hay varios servidores (o ninguno), se elige
    Connections {
        target: descubrimiento
        function onBusquedaTerminada(encontrados) {
            if (!descubrimiento.configurado && encontrados !== 1 && !selector.opened) selector.open()
        }
    }

    SelectorServidor { id: selector }

    Flickable {
        anchors.fill: parent
        contentHeight: columna.implicitHeight + 2 * Theme.spacingXl
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: columna
            width: Math.min(parent.width - 2 * Theme.spacingL, 460)
            x: (parent.width - width) / 2
            y: Theme.spacingXl
            spacing: Theme.spacingM

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 72; height: 72; radius: 20
                color: Qt.rgba(1, 1, 1, 0.18)
                Label { anchors.centerIn: parent; text: "R"; color: "white"; font.pixelSize: 38; font.weight: Font.Bold }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("REP")
                color: "white"
                font.pixelSize: Theme.fontHeadline
                font.weight: Font.Bold
            }

            Card {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingM
                padding: Theme.spacingL
                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM
                    Label { text: qsTr("Iniciar sesión"); font.pixelSize: Theme.fontTitle; font.weight: Font.Bold; color: Theme.textPrimary }
                    AppTextField {
                        id: identField
                        Layout.fillWidth: true
                        label: qsTr("Identificación")
                        placeholderText: qsTr("Número de documento")
                        field.inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                        onAccepted: passField.field.forceActiveFocus()
                    }
                    AppTextField {
                        id: passField
                        Layout.fillWidth: true
                        label: qsTr("Contraseña")
                        echoMode: TextInput.Password
                        field.inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                        onAccepted: root.entrar()
                    }
                    Label {
                        visible: loginViewModel.errorMessage !== ""
                        text: loginViewModel.errorMessage
                        color: Theme.dangerDark
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    AppButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        text: loginViewModel.isLoading ? qsTr("Verificando…") : qsTr("Entrar")
                        enabled: root.puedeEntrar
                        onClicked: root.entrar()
                    }
                }
            }

            // Servidor en uso (lo encuentra solo en la red)
            Card {
                Layout.fillWidth: true
                padding: Theme.spacingM
                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingS
                    Rectangle { width: 10; height: 10; radius: 5; color: sincronizacion.enLinea ? Theme.success : Theme.danger }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                            text: descubrimiento.buscando && !descubrimiento.configurado ? qsTr("Buscando el servidor…")
                                  : descubrimiento.servidorNombre !== "" ? descubrimiento.servidorNombre : qsTr("Servidor")
                        }
                        Label { Layout.fillWidth: true; elide: Text.ElideRight; color: Theme.textMuted; font.pixelSize: Theme.fontCaption; text: descubrimiento.servidorUrl }
                    }
                    AppButton { text: qsTr("Cambiar"); variant: "secondary"; onClicked: selector.open() }
                }
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.pixelSize: Theme.fontCaption
                text: qsTr("Conéctese a la misma red Wi-Fi del colegio (o a la red del servidor). No necesita internet.")
            }
        }
    }
}
