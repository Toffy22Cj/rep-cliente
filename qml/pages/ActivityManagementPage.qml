import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    title: "Gestión de Actividades"
    property bool createNew: false

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "\u2190"
                onClicked: stackView.pop()
            }
            Label {
                text: "Gestión de Actividades"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Filtrar por Materia: "; font.bold: true }
            ComboBox {
                id: materiaCombo
                Layout.fillWidth: true
                model: profesorViewModel.materiaModel
                textRole: "nombre"
                onActivated: profesorViewModel.loadActividades(model.get(index).id, 1) // Hardcoded curso 1 for demo
            }
        }

        ListView {
            id: activityList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: profesorViewModel.actividadModel
            spacing: 10
            clip: true

            delegate: ItemDelegate {
                width: activityList.width
                height: 100
                background: Rectangle {
                    color: "white"
                    border.color: "#ecf0f1"
                    radius: 8
                    layer.enabled: true
                }

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    Column {
                        Layout.fillWidth: true
                        Label { text: model.titulo; font.bold: true; font.pixelSize: 18; color: "#2c3e50" }
                        Label { text: "Tipo: " + model.tipo; font.pixelSize: 14; color: "#7f8c8d" }
                        Label { text: "Entrega: " + model.fechaEntrega; font.pixelSize: 14; color: "#e67e22" }
                    }
                    Column {
                        spacing: 5
                        Button {
                            text: "Editar Preguntas"
                            onClicked: stackView.push("QuestionEditorPage.qml", { actividadId: model.id })
                        }
                        Button {
                            text: "Detalles"
                            flat: true
                            onClicked: editDialog.openWith(model)
                        }
                    }
                }
            }
        }

        Button {
            text: "+ Crear Nueva Actividad"
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            highlighted: true
            onClicked: createDialog.open()
        }
    }

    Dialog {
        id: createDialog
        title: "Nueva Actividad"
        anchors.centerIn: parent
        modal: true
        width: Math.min(parent.width * 0.9, 400)
        standardButtons: Dialog.Save | Dialog.Cancel

        onAccepted: {
            profesorViewModel.createActividad(
                tituloField.text,
                tipoCombo.currentText,
                descField.text,
                fechaField.text, // Expecting YYYY-MM-DD
                parseInt(durField.text),
                profesorViewModel.materiaModel.get(materiaCombo.currentIndex).id,
                1 // Hardcoded curso
            )
        }

        ColumnLayout {
            width: parent.width
            spacing: 10

            TextField { id: tituloField; placeholderText: "Título"; Layout.fillWidth: true }
            ComboBox { id: tipoCombo; model: ["EXAMEN", "QUIZ", "TALLER", "TAREA"]; Layout.fillWidth: true }
            TextArea { id: descField; placeholderText: "Descripción"; Layout.fillWidth: true; Layout.preferredHeight: 80 }
            TextField { id: fechaField; placeholderText: "Fecha Entrega (YYYY-MM-DD)"; Layout.fillWidth: true }
            TextField { id: durField; placeholderText: "Duración (minutos)"; Layout.fillWidth: true; inputMethodHints: Qt.ImhDigitsOnly }
        }
    }

    Component.onCompleted: {
        profesorViewModel.loadMaterias()
        if (createNew) createDialog.open()
    }
}
