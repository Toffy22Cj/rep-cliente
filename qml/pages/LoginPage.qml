import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    signal loginSuccess()
    background: Rectangle { color: Theme.background }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- Panel de marca (se oculta en ventanas estrechas) ----
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.width * 0.45
            visible: root.width >= 900
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.primary }
                GradientStop { position: 1.0; color: Theme.sidebar }
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 56
                spacing: Theme.spacingM

                Rectangle {
                    width: 56; height: 56; radius: Theme.radiusL
                    color: Qt.rgba(1, 1, 1, 0.15)
                    Label {
                        anchors.centerIn: parent
                        text: "R"
                        color: "white"
                        font.pixelSize: 28
                        font.weight: Font.Bold
                    }
                }
                Label {
                    text: "REP"
                    color: "white"
                    font.pixelSize: Theme.fontDisplay
                    font.weight: Font.Bold
                }
                Label {
                    text: qsTr("Plataforma de gestión educativa")
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.pixelSize: Theme.fontTitle
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Label {
                    text: qsTr("Actividades, calificaciones, asistencia y reportes en un solo lugar para estudiantes, profesores y administradores.")
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: Theme.fontSubtitle
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingS
                }
            }
        }

        // ---- Formulario ----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Card {
                anchors.centerIn: parent
                width: Math.min(parent.width - 2 * Theme.spacingL, 420)
                padding: Theme.spacingXl

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM

                    Label {
                        text: qsTr("Iniciar sesión")
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontHeadline
                        font.weight: Font.Bold
                    }
                    Label {
                        text: qsTr("Ingrese sus credenciales para continuar")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontBody
                        Layout.bottomMargin: Theme.spacingS
                    }

                    AppTextField {
                        id: identField
                        Layout.fillWidth: true
                        label: qsTr("Identificación")
                        placeholderText: qsTr("Número de documento")
                        field.inputMethodHints: Qt.ImhPreferNumbers
                        onAccepted: passField.field.forceActiveFocus()
                        Component.onCompleted: field.forceActiveFocus()
                    }

                    AppTextField {
                        id: passField
                        Layout.fillWidth: true
                        label: qsTr("Contraseña")
                        placeholderText: "••••••••"
                        echoMode: TextInput.Password
                        onAccepted: root.submit()
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: loginViewModel.errorMessage !== ""
                        implicitHeight: errorLabel.implicitHeight + Theme.spacingM
                        radius: Theme.radiusM
                        color: Theme.dangerSoft
                        Label {
                            id: errorLabel
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            text: loginViewModel.errorMessage
                            color: Theme.dangerDark
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    AppButton {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.spacingS
                        text: loginViewModel.isLoading ? qsTr("Verificando…") : qsTr("Entrar")
                        enabled: root.canSubmit
                        onClicked: root.submit()
                    }

                    BusyIndicator {
                        running: loginViewModel.isLoading
                        visible: running
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 32
                        implicitHeight: 32
                    }
                }
            }
        }
    }

    readonly property bool canSubmit: !loginViewModel.isLoading
                                      && identField.text.trim() !== ""
                                      && passField.text !== ""

    function submit() {
        if (canSubmit)
            loginViewModel.login(identField.text.trim(), passField.text)
    }

    Connections {
        target: loginViewModel
        function onLoginSuccess(role) {
            passField.text = ""
            root.loginSuccess()
        }
    }
}
