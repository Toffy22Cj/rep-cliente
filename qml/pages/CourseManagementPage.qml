import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    title: "Gestión de Cursos"
    background: Rectangle { color: Theme.background }
    property var stackView: StackView.view

    Component.onCompleted: adminViewModel.loadCursos()

    Connections {
        target: adminViewModel
        function onOperationSuccess(msg) {
            adminViewModel.loadCursos()
            createDialog.close()
        }
    }

    header: PageHeader { title: "Gestión de Cursos" }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Button {
            text: "+ Nuevo Curso"
            highlighted: true
            onClicked: createDialog.openCreate()
        }

        ListView {
            id: courseList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: adminViewModel.cursoModel
            spacing: 8

            delegate: Rectangle {
                width: courseList.width
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
                        color: Theme.warning
                        Label { anchors.centerIn: parent; text: "🎓"; }
                    }

                    Label { 
                        text: "Grado " + model.grado + " - Grupo " + model.grupo
                        font.bold: true
                        font.pixelSize: 16
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "✏️"
                        flat: true
                        onClicked: createDialog.openEdit(model.id, model.grado, model.grupo)
                    }

                    Button {
                        text: "🗑️"
                        flat: true
                        onClicked: adminViewModel.deleteCurso(model.id)
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
        title: editMode ? "Editar Curso" : "Nuevo Curso"
        standardButtons: Dialog.Save | Dialog.Cancel

        property bool editMode: false
        property int editId: 0

        function openCreate() {
            editMode = false
            editId = 0
            gradoField.text = ""
            grupoField.text = ""
            open()
        }

        function openEdit(id, grado, grupo) {
            editMode = true
            editId = id
            gradoField.text = grado
            grupoField.text = grupo
            open()
        }

        ColumnLayout {
            width: parent.width
            spacing: 15

            TextField {
                id: gradoField
                placeholderText: "Grado (Ej: 11)"
                validator: IntValidator { bottom: 1; top: 12 }
                Layout.fillWidth: true
            }
            TextField {
                id: grupoField
                placeholderText: "Grupo (Ej: A)"
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            if (editMode) {
                adminViewModel.updateCurso(editId, parseInt(gradoField.text), grupoField.text)
            } else {
                adminViewModel.createCurso(parseInt(gradoField.text), grupoField.text)
            }
            gradoField.clear(); grupoField.clear()
        }
    }
}
