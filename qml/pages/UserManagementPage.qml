import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Page {
    id: root
    title: "Gestión de Usuarios"
    background: Rectangle { color: "#f4f6f9" }
    property var stackView: StackView.view

    Component.onCompleted: adminViewModel.loadUsuarios()

    Connections {
        target: adminViewModel
        function onOperationSuccess(msg) {
            console.log(msg)
            adminViewModel.loadUsuarios()
            editDialog.close()
        }
    }

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "←"
                onClicked: stackView.pop()
                contentItem: Text { text: "←"; color: "white"; font.pixelSize: 24; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Label { text: "Gestión de Usuarios"; color: "white"; font.bold: true; font.pixelSize: 18 }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Header Actions
        RowLayout {
            Layout.fillWidth: true
            TextField {
                placeholderText: "Buscar usuario..."
                Layout.fillWidth: true
                // Filtering to be implemented later
            }
            Button {
                text: "↻ Actualizar"
                onClicked: adminViewModel.loadUsuarios()
            }
        }

        // List
        ListView {
            id: userList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: adminViewModel.usuarioModel
            spacing: 8

            delegate: Rectangle {
                width: userList.width
                height: 80
                color: "white"
                radius: 8
                border.color: "#ecf0f1"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: model.rol === "ADMIN" ? "#e74c3c" : (model.rol === "PROFESOR" ? "#3498db" : "#2ecc71")
                        Label {
                            anchors.centerIn: parent
                            text: model.nombre ? model.nombre.charAt(0).toUpperCase() : "?"
                            color: "white"
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: model.nombre; font.bold: true; font.pixelSize: 16 }
                        Label { text: model.correo; color: "#7f8c8d" }
                    }

                    Label {
                        text: model.rol
                        font.bold: true
                        color: model.rol === "ADMIN" ? "#c0392b" : "#7f8c8d"
                    }

                    Switch {
                        checked: model.activo
                        text: checked ? "Activo" : "Inactivo"
                        onToggled: adminViewModel.toggleUsuarioEstado(model.id, checked)
                    }

                    Button {
                        text: "✏️"
                        flat: true
                        onClicked: {
                            editDialog.userId = model.id
                            nameField.text = model.nombre
                            emailField.text = model.correo
                            rolCombo.currentIndex = rolCombo.indexOfValue(model.rol)
                            editDialog.open()
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: editDialog
        anchors.centerIn: parent
        width: 350
        modal: true
        title: "Editar Usuario"
        standardButtons: Dialog.Save | Dialog.Cancel

        property var userId: 0

        ColumnLayout {
            width: parent.width
            spacing: 15
            
            TextField { id: nameField; placeholderText: "Nombre"; Layout.fillWidth: true }
            TextField { id: emailField; placeholderText: "Correo"; Layout.fillWidth: true }
            ComboBox {
                id: rolCombo
                Layout.fillWidth: true
                model: ["ESTUDIANTE", "PROFESOR", "ADMIN"]
            }
            TextField { 
                id: passField
                placeholderText: "Nueva Contraseña (opcional)"
                echoMode: TextInput.Password
                Layout.fillWidth: true 
            }
        }

        onAccepted: {
            adminViewModel.saveUsuario(
                userId, 
                nameField.text, 
                emailField.text, 
                rolCombo.currentText,
                passField.text,
                true // Keep active default true for now on edit
            )
            passField.clear()
        }
    }
}
