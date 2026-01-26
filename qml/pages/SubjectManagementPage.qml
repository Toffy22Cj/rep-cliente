import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Page {
    id: root
    title: "Gestión de Materias"
    background: Rectangle { color: "#f4f6f9" }
    property var stackView: StackView.view

    Component.onCompleted: adminViewModel.loadMaterias()

    Connections {
        target: adminViewModel
        function onOperationSuccess(msg) {
            adminViewModel.loadMaterias()
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
            Label { text: "Gestión de Materias"; color: "white"; font.bold: true; font.pixelSize: 18 }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Button {
            text: "+ Nueva Materia"
            highlighted: true
            onClicked: createDialog.open()
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
                border.color: "#ecf0f1"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 20

                    Rectangle {
                        width: 30; height: 30; radius: 15
                        color: "#9b59b6"
                        Label { anchors.centerIn: parent; text: "📖"; }
                    }

                    Label { 
                        text: model.nombre
                        font.bold: true
                        font.pixelSize: 16
                        Layout.fillWidth: true
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
        title: "Nueva Materia"
        standardButtons: Dialog.Save | Dialog.Cancel

        TextField { 
            id: nombreField
            placeholderText: "Nombre de la Materia" 
            width: parent.width
        }

        onAccepted: {
            adminViewModel.createMateria(nombreField.text)
            nombreField.clear()
        }
    }
}
