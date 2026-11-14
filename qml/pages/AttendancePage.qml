import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    title: "Control de Asistencia"

    header: PageHeader { title: "Control de Asistencia" }

    // Local model to track attendance changes before saving
    ListModel { id: localAttendanceModel }
    Connections {
        target: localAttendanceModel
        function onDataChanged() { root.conteoVersion++ }
        function onCountChanged() { root.conteoVersion++ }
    }

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
                    root.tryAutoLoad()
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
                    root.tryAutoLoad()
                }
            }

            Label { text: "Fecha:"; font.bold: true }
            TextField {
                id: fechaField
                Layout.fillWidth: true
                // Fecha local (toISOString usaba UTC y por la noche proponía el día siguiente)
                text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                placeholderText: "YYYY-MM-DD"
                onEditingFinished: updateData()
            }
        }

        // Días con asistencia ya registrada (los más recientes): pulsar uno lo abre
        RowLayout {
            Layout.fillWidth: true
            visible: root.fechasRegistradas.length > 0
            spacing: Theme.spacingS
            Label { text: qsTr("Registrados:"); color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
            Repeater {
                model: root.fechasRegistradas.slice(0, 8)
                delegate: AppButton {
                    required property string modelData
                    text: { const d = new Date(modelData + "T12:00:00"); return ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"][d.getDay()] + " " + Qt.formatDate(d, "dd/MM") }
                    variant: fechaField.text === modelData ? "primary" : "secondary"
                    onClicked: { fechaField.text = modelData; root.updateData() }
                }
            }
            Label {
                visible: root.fechasRegistradas.length > 8
                text: qsTr("y %n más", "", root.fechasRegistradas.length - 8)
                color: Theme.textMuted; font.pixelSize: Theme.fontCaption
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: localAttendanceModel.count > 0
            spacing: Theme.spacingS
            Label {
                text: qsTr("Presentes %1 · Retardos %2 · Excusas %3 · Ausentes %4")
                      .arg(root.conteo("PRESENTE")).arg(root.conteo("RETARDO")).arg(root.conteo("EXCUSA")).arg(root.conteo("NO_INGRESO"))
                color: Theme.textSecondary
                Layout.fillWidth: true
            }
            AppButton { text: qsTr("Todos presentes"); variant: "secondary"; onClicked: root.marcarTodos("PRESENTE") }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
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
                    color: index % 2 === 0 ? Theme.surfaceAlt : "white"
                    radius: 4
                    border.color: Theme.border
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
                        color: Theme.textPrimary
                    }
                    
                    // Estado: botonera segmentada (un clic por estudiante)
                    Row {
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: root.estados
                            delegate: AppButton {
                                required property var modelData
                                text: modelData.texto
                                variant: model.estado === modelData.valor ? "primary" : "secondary"
                                Accessible.name: qsTr("%1: %2").arg(model.nombreEstudiante).arg(modelData.texto)
                                onClicked: localAttendanceModel.setProperty(model.index, "estado", modelData.valor)
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

    // Carga automática en cuanto ambos combos tienen selección. Antes solo se
    // disparaba si los modelos cambiaban con la página abierta, y como el dashboard
    // ya los había cargado, al entrar no se mostraba ningún estudiante.
    property bool autoLoaded: false
    function tryAutoLoad() {
        if (!autoLoaded && cursoCombo.count > 0 && materiaCombo.count > 0) {
            if (cursoCombo.currentIndex < 0) cursoCombo.currentIndex = 0
            if (materiaCombo.currentIndex < 0) materiaCombo.currentIndex = 0
            autoLoaded = true
            updateData()
        }
    }

    property var fechasRegistradas: []
    readonly property var estados: [
        { valor: "PRESENTE", texto: qsTr("Presente") },
        { valor: "RETARDO", texto: qsTr("Retardo") },
        { valor: "EXCUSA", texto: qsTr("Excusa") },
        { valor: "NO_INGRESO", texto: qsTr("Ausente") }
    ]
    property int conteoVersion: 0
    function conteo(valor) {
        conteoVersion // dependencia para recalcular
        let n = 0
        for (let i = 0; i < localAttendanceModel.count; i++) if (localAttendanceModel.get(i).estado === valor) n++
        return n
    }
    function marcarTodos(valor) {
        for (let i = 0; i < localAttendanceModel.count; i++) localAttendanceModel.setProperty(i, "estado", valor)
    }
    ApiRequests { id: requests }
    Toast { id: toast }

    function cargarFechas() {
        const c = profesorViewModel.cursoModel.get(cursoCombo.currentIndex)
        const m = profesorViewModel.materiaModel.get(materiaCombo.currentIndex)
        if (!c || !m) return
        requests.get("/profesor/asistencia/fechas?cursoId=" + c.id + "&materiaId=" + m.id,
                     datos => { fechasRegistradas = (datos || []).slice().sort().reverse() },
                     () => { fechasRegistradas = [] })
    }

    function updateData() {
        if (cursoCombo.currentIndex < 0 || materiaCombo.currentIndex < 0) {
            return;
        }
        cargarFechas()
        
        localAttendanceModel.clear()
        
        var cursoObj = profesorViewModel.cursoModel.get(cursoCombo.currentIndex)
        var materiaObj = profesorViewModel.materiaModel.get(materiaCombo.currentIndex)
        
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
                toast.mostrar(qsTr("Asistencia del %1 guardada").arg(fechaField.text), "exito")
                root.cargarFechas()
            }
        }
    }

    Component.onCompleted: {
        profesorViewModel.loadCursos()
        profesorViewModel.loadMaterias()
        Qt.callLater(tryAutoLoad)
    }
}
