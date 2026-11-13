import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    title: "Gestión de Materias"
    background: Rectangle { color: Theme.background }
    property var stackView: StackView.view

    Component.onCompleted: adminViewModel.loadMaterias()

    Connections {
        target: adminViewModel
        function onOperationSuccess(msg) {
            adminViewModel.loadMaterias()
            createDialog.close()
        }
    }

    header: PageHeader { title: "Gestión de Materias" }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Button {
            text: "+ Nueva Materia"
            highlighted: true
            onClicked: createDialog.openCreate()
        }

        ListView {
            id: subjectList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: adminViewModel.materiaModel
            spacing: 8

            delegate: Rectangle {
                width: subjectList.width
                height: 60
                color: "white"
                radius: 8
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 20

                    Rectangle {
                        width: 30; height: 30; radius: 15
                        color: Theme.purple
                        Label { anchors.centerIn: parent; text: "📖"; }
                    }

                    Label { 
                        text: model.nombre
                        font.bold: true
                        font.pixelSize: 16
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "✏️"
                        flat: true
                        onClicked: createDialog.openEdit(model.id, model.nombre)
                    }

                    Button {
                        text: "🗑️"
                        flat: true
                        onClicked: adminViewModel.deleteMateria(model.id)
                    }
                }
            }
        }
    }

    Dialog {
        id: createDialog
        anchors.centerIn: parent
        width: 300
        modal: true
        title: editMode ? "Editar Materia" : "Nueva Materia"
        standardButtons: Dialog.Save | Dialog.Cancel

        property bool editMode: false
        property int editId: 0

        function openCreate() {
            editMode = false
            editId = 0
            nombreField.text = ""
            open()
        }

        function openEdit(id, nombre) {
            editMode = true
            editId = id
            nombreField.text = nombre
            open()
        }

        TextField {
            id: nombreField
            placeholderText: "Nombre de la Materia"
            width: parent.width
        }

        onAccepted: {
            if (editMode) {
                adminViewModel.updateMateria(editId, nombreField.text)
            } else {
                adminViewModel.createMateria(nombreField.text)
            }
            nombreField.clear()
        }
    }
}
