import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    signal loginSuccess()
    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2c3e50" }
            GradientStop { position: 1.0; color: "#000000" }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, 400)
        spacing: 20

        Label {
            text: "REP"
            font.pointSize: 40
            font.bold: true
            color: "white"
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Bienvenido de nuevo"
            font.pointSize: 14
            color: "#bdc3c7"
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 20
        }

        TextField {
            id: identField
            placeholderText: "Identificación"
            Layout.fillWidth: true
            font.pointSize: 12
            color: "white"
            background: Rectangle {
                color: "#34495e"
                radius: 5
                border.color: identField.activeFocus ? "#3498db" : "transparent"
            }
        }

        TextField {
            id: passField
            placeholderText: "Contraseña"
            echoMode: TextInput.Password
            Layout.fillWidth: true
            font.pointSize: 12
            color: "white"
            background: Rectangle {
                color: "#34495e"
                radius: 5
                border.color: passField.activeFocus ? "#3498db" : "transparent"
            }
        }

        Button {
            text: "Iniciar Sesión"
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: 12
            enabled: !loginViewModel.isLoading && identField.text !== "" && passField.text !== ""
            
            contentItem: Text {
                text: parent.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: parent.font
            }

            background: Rectangle {
                color: parent.down ? "#2980b9" : "#3498db"
                radius: 5
            }

            onClicked: loginViewModel.login(identField.text, passField.text)
        }

        Label {
            id: statusLabel // Added id for statusLabel
            text: loginViewModel.errorMessage
            color: "#e74c3c"
            font.pointSize: 10
            Layout.alignment: Qt.AlignHCenter
            visible: loginViewModel.errorMessage !== ""
        }

        BusyIndicator {
            running: loginViewModel.isLoading
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Connections {
        target: loginViewModel
        function onLoginSuccess(role) {
            root.loginSuccess()
        }
    }
}
