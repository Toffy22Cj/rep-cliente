import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    signal loginSuccess()
    
    Component.onCompleted: {
        console.log("LoginPage.qml Component.onCompleted")
        console.log("loginViewModel disponible:", loginViewModel !== undefined)
        if (loginViewModel !== undefined && loginViewModel.loginSuccess !== undefined) {
            loginViewModel.loginSuccess.connect(function(role) {
                console.log("LoginPage: loginSuccess conectado, rol:", role)
                root.loginSuccess()
            })
            console.log("✓ LoginPage: Conexión establecida a loginViewModel.loginSuccess")
        }
    }
    
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
            // Allow alphanumeric and hyphens, 3-20 chars
            validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z0-9-]{0,20}$/ }
            background: Rectangle {
                color: "#34495e"
                radius: 5
                border.color: identField.activeFocus ? "#3498db" : (identField.text.length > 0 && identField.text.length < 3 ? "#e74c3c" : "transparent")
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
                border.color: passField.activeFocus ? "#3498db" : (passField.text.length > 0 && passField.text.length < 6 ? "#e74c3c" : "transparent")
            }
        }

        Button {
            id: loginButton
            text: "Iniciar Sesión"
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: 12
            // Temporarily enable always to test if clicks are received
            enabled: true 
            
            contentItem: Text {
                text: loginButton.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: loginButton.font
            }

            background: Rectangle {
                id: buttonBg
                color: loginButton.down ? "#2980b9" : "#3498db"
                radius: 5
                // Visual marker: show a red border if it's "pressed" but might not fire onClicked
                border.width: loginButton.pressed ? 3 : 0
                border.color: "yellow"
            }

            onPressed: console.log("QML: Botón PRESIONADO (onPressed)")
            onReleased: console.log("QML: Botón LIBERADO (onReleased)")
            onClicked: {
                console.log("!!! BOTÓN CLICKADO !!!")
                console.log("QML: Identificación:", identField.text)
                console.log("QML: Longitud pass:", passField.text.length)
                
                if (typeof loginViewModel === "undefined") {
                    console.error("❌ ERROR: loginViewModel is UNDEFINED at click time!")
                } else {
                    console.log("QML: Llamando a loginViewModel.login...")
                    loginViewModel.login(identField.text, passField.text)
                }
            }
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
}
