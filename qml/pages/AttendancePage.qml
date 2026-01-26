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
                onCountChanged: {
                    if (count > 0 && currentIndex === -1) currentIndex = 0
                    console.log("CursoCombo count:", count)
                }
            }

            Label { text: "Materia:"; font.bold: true }
            ComboBox {
                id: materiaCombo
                Layout.fillWidth: true
                model: profesorViewModel.materiaModel
                textRole: "nombre"
                onActivated: updateData()
                onCountChanged: {
                    if (count > 0 && currentIndex === -1) currentIndex = 0
                    console.log("MateriaCombo count:", count)
                    // Auto-load when both combos are ready
                    if (count > 0 && cursoCombo.count > 0 && currentIndex >= 0 && cursoCombo.currentIndex >= 0) {
                        updateData()
                    }
                }
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
                height: 120
                background: Rectangle {
                    color: index % 2 === 0 ? "#f9f9f9" : "white"
                    radius: 4
                    border.color: "#dfe6e9"
                    border.width: 1
                }

                contentItem: GridLayout {
                    columns: 2
                    rows: 3
                    columnSpacing: 10
                    rowSpacing: 5
                    anchors.fill: parent
                    anchors.margins: 10
                    
                    // Nombre del estudiante (span 2 columns)
                    Label {
                        text: model.nombreEstudiante
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        font.bold: true
                        font.pixelSize: 15
                        color: "#2c3e50"
                    }
                    
                    // Estado
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Label { 
                            text: "Estado:" 
                            width: 55
                            font.pixelSize: 13
                        }
                        ComboBox {
                            id: estadoCombo
                            Layout.fillWidth: true
                            model: ["PRESENTE", "NO_INGRESO", "EXCUSA"]
                            currentIndex: {
                                var idx = estadoCombo.model.indexOf(model.estado)
                                return idx >= 0 ? idx : 1
                            }
                            onActivated: (index) => {
                                localAttendanceModel.setProperty(model.index, "estado", currentText)
                            }
                        }
                    }
                    
                    // Tipo de Excusa (solo visible si estado == EXCUSA)
                    RowLayout {
                        Layout.fillWidth: true
                        visible: model.estado === "EXCUSA"
                        spacing: 5
                        Label { 
                            text: "Excusa:" 
                            width: 55
                            font.pixelSize: 13
                        }
                        ComboBox {
                            id: excusaCombo
                            Layout.fillWidth: true
                            model: ["MEDICA", "PERSONAL", "FAMILIAR", "OTRA"]
                            currentIndex: {
                                var idx = excusaCombo.model.indexOf(model.tipoExcusa)
                                return idx >= 0 ? idx : 0
                            }
                            onActivated: (index) => {
                                localAttendanceModel.setProperty(model.index, "tipoExcusa", currentText)
                            }
                        }
                    }
                    
                    // Observación (span 2 columns)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        spacing: 5
                        Label { 
                            text: "Obs:" 
                            width: 40
                            font.pixelSize: 13
                        }
                        TextField {
                            Layout.fillWidth: true
                            text: model.observacion || ""
                            placeholderText: "Observaciones..."
                            font.pixelSize: 12
                            onEditingFinished: {
                                localAttendanceModel.setProperty(model.index, "observacion", text)
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Button {
                text: "🔄 Refrescar"
                Layout.preferredHeight: 40
                onClicked: updateData()
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
                            estado: item.estado,
                            tipoExcusa: item.tipoExcusa || "",
                            observacion: item.observacion || ""
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
    }

    function updateData() {
        if (cursoCombo.currentIndex < 0 || materiaCombo.currentIndex < 0) {
            console.log("AttendancePage: Combos not ready:", cursoCombo.currentIndex, materiaCombo.currentIndex)
            return;
        }
        
        localAttendanceModel.clear()
        
        var cursoObj = profesorViewModel.cursoModel.get(cursoCombo.currentIndex)
        var materiaObj = profesorViewModel.materiaModel.get(materiaCombo.currentIndex)
        
        console.log("AttendancePage: Loading asistencia for curso:", cursoObj.id, "materia:", materiaObj.id, "fecha:", fechaField.text)
        
        profesorViewModel.loadAsistencia(
            cursoObj.id,
            materiaObj.id,
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
                       estado: "NO_INGRESO",
                       tipoExcusa: "",
                       observacion: ""
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
