import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Page {
    id: root
    title: "Gestión de Cursos"
    background: Rectangle { color: "#f4f6f9" }
    property var stackView: StackView.view

    Component.onCompleted: adminViewModel.loadCursos()

    Connections {
        target: adminViewModel
        function onOperationSuccess(msg) {
            adminViewModel.loadCursos()
            createDialog.close()
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
            Label { text: "Gestión de Cursos"; color: "white"; font.bold: true; font.pixelSize: 18 }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Button {
            text: "+ Nuevo Curso"
            highlighted: true
            onClicked: createDialog.open()
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
                border.color: "#ecf0f1"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 20

                    Rectangle {
                        width: 30; height: 30; radius: 15
                        color: "#e67e22"
                        Label { anchors.centerIn: parent; text: "🎓"; }
                    }

                    Label { 
                        text: "Grado " + model.grado + " - Grupo " + model.grupo
                        font.bold: true
                        font.pixelSize: 16
                        Layout.fillWidth: true
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
        title: "Nuevo Curso"
        standardButtons: Dialog.Save | Dialog.Cancel

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
            adminViewModel.createCurso(parseInt(gradoField.text), grupoField.text)
            gradoField.clear(); grupoField.clear()
        }
    }
}
