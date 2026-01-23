import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    title: "Control de Asistencia"

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "\u2190"
                onClicked: stackView.pop()
            }
            Label {
                text: "Control de Asistencia"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
        }
    }

    // Local model to track attendance changes before saving
    ListModel { id: localAttendanceModel }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            
            Label { text: "Curso:"; font.bold: true }
            ComboBox {
                id: cursoCombo
                Layout.fillWidth: true
                model: profesorViewModel.cursoModel
                textRole: "nombre"
                onActivated: updateData()
            }

            Label { text: "Materia:"; font.bold: true }
            ComboBox {
                id: materiaCombo
                Layout.fillWidth: true
                model: profesorViewModel.materiaModel
                textRole: "nombre"
                onActivated: updateData()
            }

            Label { text: "Fecha:"; font.bold: true }
            TextField {
                id: fechaField
                Layout.fillWidth: true
                text: new Date().toISOString().split('T')[0]
                placeholderText: "YYYY-MM-DD"
                onEditingFinished: updateData()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#ecf0f1"
        }

        ListView {
            id: studentList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: localAttendanceModel
            spacing: 5
            clip: true

            delegate: ItemDelegate {
                width: studentList.width
                height: 50
                background: Rectangle {
                    color: index % 2 === 0 ? "#f9f9f9" : "white"
                    radius: 4
                }

                contentItem: RowLayout {
                    spacing: 15
                    Label {
                        text: model.nombreEstudiante
                        Layout.fillWidth: true
                        font.pixelSize: 16
                    }
                    CheckBox {
                        checked: model.asistio
                        onToggled: model.asistio = checked
                    }
                }
            }
        }

        Button {
            text: "Guardar Asistencia"
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            highlighted: true
            enabled: localAttendanceModel.count > 0
            onClicked: {
                let data = []
                for (let i = 0; i < localAttendanceModel.count; i++) {
                    let item = localAttendanceModel.get(i)
                    data.push({
                        estudianteId: item.estudianteId,
                        nombreEstudiante: item.nombreEstudiante,
                        asistio: item.asistio,
                        observaciones: ""
                    })
                }
                profesorViewModel.saveAsistencia(
                    profesorViewModel.cursoModel.get(cursoCombo.currentIndex).id,
                    profesorViewModel.materiaModel.get(materiaCombo.currentIndex).id,
                    fechaField.text,
                    data
                )
            }
        }
    }

    function updateData() {
        if (cursoCombo.currentIndex < 0 || materiaCombo.currentIndex < 0) return;
        localAttendanceModel.clear()
        profesorViewModel.loadAsistencia(
            profesorViewModel.cursoModel.get(cursoCombo.currentIndex).id,
            profesorViewModel.materiaModel.get(materiaCombo.currentIndex).id,
            fechaField.text
        )
    }

    Connections {
        target: profesorViewModel
        function onAsistenciaFetched(asistencia) {
            localAttendanceModel.clear()
            if (asistencia.length === 0) {
                // No attendance record found, load students to create new one
                if (cursoCombo.currentIndex >= 0) {
                   profesorViewModel.loadEstudiantes(profesorViewModel.cursoModel.get(cursoCombo.currentIndex).id)
                }
            } else {
                for (let i = 0; i < asistencia.length; i++) {
                    localAttendanceModel.append(asistencia[i])
                }
            }
        }
        function onEstudiantesFetched(estudiantes) {
           // Called when we need to populate for new attendance
           // Check if we are in this page context or add a flag if shared viewmodel
           // For simplicity, we just append if the model is empty (which we cleared above)
           if (localAttendanceModel.count === 0) {
               for (let i = 0; i < estudiantes.length; i++) {
                   localAttendanceModel.append({
                       estudianteId: estudiantes[i].id,
                       nombreEstudiante: estudiantes[i].nombre,
                       asistio: false, // Default to false or true as desired
                       observaciones: ""
                   })
               }
           }
        }
        function onAsistenciaSaved(success) {
            if (success) {
                // Show success message or toast (not implemented in this simplified UI)
                console.log("Asistencia guardada con éxito")
            }
        }
    }

    Component.onCompleted: {
        profesorViewModel.loadCursos()
        profesorViewModel.loadMaterias()
    }
}
