import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    title: "Gestión de Asignaciones"

    Component.onCompleted: {
        adminViewModel.loadAsignaciones()
        adminViewModel.loadUsuarios() // Need professors
        adminViewModel.loadMaterias()
        adminViewModel.loadCursos()
    }

    // Main layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Header
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "Asignaciones Profesor-Materia"
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
            }
            Button {
                text: "+ Nueva Asignación"
                highlighted: true
                onClicked: createDialog.open()
            }
        }

        // List
        ListView {
            id: assignmentsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            model: adminViewModel.asignacionModel

            delegate: Rectangle {
                width: ListView.view.width
                height: 80
                color: "white"
                radius: 8
                border.color: "#e0e0e0"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        Label { 
                            text: model.profesorNombre 
                            font.bold: true
                            font.pixelSize: 16
                        }
                        Label { 
                            text: model.materiaNombre + " - " + model.cursoNombre
                            color: "#666" 
                        }
                    }

                    Button {
                        text: "Eliminar"
                        flat: true
                        // Material.foreground: Material.Red 
                        onClicked: deleteDialog.openWith(model.id)
                    }
                }
            }
        }
    }

        // Create Dialog
    Dialog {
        id: createDialog
        title: "Nueva Asignación"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel



        ColumnLayout {
            width: 400
            spacing: 15

            Label { text: "Profesor"; font.bold: true }
            ComboBox {
                id: profesorCombo
                Layout.fillWidth: true
                model: adminViewModel.usuarioModel
                textRole: "nombre"
                valueRole: "id"
            }

            Label { text: "Materia"; font.bold: true }
            ComboBox {
                id: materiaCombo
                Layout.fillWidth: true
                model: adminViewModel.materiaModel
                textRole: "nombre"
                valueRole: "id"
            }

            Label { text: "Curso"; font.bold: true }
            ComboBox {
                id: cursoCombo
                Layout.fillWidth: true
                model: adminViewModel.cursoModel
                textRole: "displayName"
                valueRole: "id"
            }
        }

        onAccepted: {
            // Use currentValue directly
            var profId = profesorCombo.currentValue
            var matId = materiaCombo.currentValue
            var curId = cursoCombo.currentValue

            console.log("Creating Assignment:", profId, matId, curId)
            adminViewModel.createAsignacion(profId, matId, curId)
        }
    }

    // Delete Confirmation
    Dialog {
        id: deleteDialog
        title: "Confirmar Eliminación"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        property var assignId: 0

        function openWith(id) {
            assignId = id
            open()
        }

        Text {
            text: "¿Estás seguro de eliminar esta asignación?"
        }

        onAccepted: {
            adminViewModel.deleteAsignacion(deleteDialog.assignId)
        }
    }
}
