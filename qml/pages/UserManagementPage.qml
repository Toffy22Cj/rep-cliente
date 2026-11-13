import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    title: "Gestión de Usuarios"
    background: Rectangle { color: Theme.background }
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

    header: PageHeader { title: "Gestión de Usuarios" }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Header Actions
        RowLayout {
            Layout.fillWidth: true
            AppTextField {
                id: searchField
                placeholderText: qsTr("Buscar por nombre, correo o rol…")
                Layout.fillWidth: true
            }
            AppButton {
                text: qsTr("\u21BB Actualizar")
                variant: "secondary"
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

            // Filtro local: oculta las filas que no coinciden con la búsqueda
            function matches(nombre, correo, rol) {
                const q = searchField.text.trim().toLowerCase()
                return q === "" || (nombre + " " + correo + " " + rol).toLowerCase().indexOf(q) !== -1
            }

            delegate: Rectangle {
                readonly property bool shown: userList.matches(model.nombre || "", model.correo || "", model.rol || "")
                visible: shown
                width: userList.width
                height: shown ? 80 : 0
                color: Theme.surface
                radius: Theme.radiusM
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: model.rol === "ADMIN" ? Theme.danger : (model.rol === "PROFESOR" ? Theme.primary : Theme.success)
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
                        Label { text: model.nombre; font.weight: Font.DemiBold; font.pixelSize: Theme.fontSubtitle; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: model.correo; color: Theme.textSecondary; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    Item {
                        Layout.preferredWidth: 130
                        implicitHeight: rolBadge.implicitHeight
                        Badge {
                            id: rolBadge
                            text: model.rol
                            tint: model.rol === "ADMIN" ? Theme.dangerDark : (model.rol === "PROFESOR" ? Theme.primary : Theme.successDark)
                            softTint: model.rol === "ADMIN" ? Theme.dangerSoft : (model.rol === "PROFESOR" ? Theme.primarySoft : Theme.successSoft)
                        }
                    }

                    Switch {
                        Layout.preferredWidth: 140
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
