import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    background: Rectangle { color: Theme.background }
    
    // CORREGIDO: Cambiar readonly a property normal
    property color primaryColor: Theme.primary
    property color sidebarColor: Theme.textPrimary
    property color textColor: Theme.textPrimary
    property color accentColor: Theme.danger
    
    // Agregar referencia al StackView
    property var stackView: StackView.view
    
    Component.onCompleted: {
        console.log("TeacherDashboard cargado")
        profesorViewModel.loadDashboard()
        profesorViewModel.loadMaterias()
        profesorViewModel.loadCursos()
        
        // Verificar que los modelos tengan datos
        Qt.callLater(function() {
            // Note: direct access to count property of C++ model might not work like this depending on implementation
            // but keeping user's debug code as requested
            // console.log("Materias cargadas:", profesorViewModel.materiaModel.count) 
        })
    }

    // Function to reload activities based on selection
    // Listen for creation signals
    Connections {
        target: profesorViewModel
        function onActividadCreada(id) {
            console.log("Activity created, refreshing list...")
            refreshActividades()
        }
    }

    function refreshActividades() {
        if (materiaCombo.currentIndex >= 0 && cursoCombo.currentIndex >= 0) {
            // Check count first to avoid index out of bounds if model changed
            if (materiaCombo.count > materiaCombo.currentIndex && 
                cursoCombo.count > cursoCombo.currentIndex) {
                
                var materiaObj = profesorViewModel.materiaModel.get(materiaCombo.currentIndex)
                var cursoObj = profesorViewModel.cursoModel.get(cursoCombo.currentIndex)
                
                if (materiaObj && cursoObj) {
                    console.log("Auto-loading actividades for:", materiaObj.id, cursoObj.id)
                    profesorViewModel.loadActividades(materiaObj.id, cursoObj.id)
                }
            }
        }
    }

    // Sidebar drawer - CORREGIDO: width dinámico
    Drawer {
        id: navDrawer
        width: Math.min(260, root.width * 0.8)
        height: root.height
        interactive: true
        position: 0
        modal: false
        
        edge: Qt.LeftEdge

        Rectangle {
            anchors.fill: parent
            color: sidebarColor

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // User Profile Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    color: "transparent"
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 70
                            height: 70
                            radius: 35
                            color: primaryColor
                            border.color: "white"
                            border.width: 2
                            
                            Label {
                                anchors.centerIn: parent
                                text: sessionManager.userName ? sessionManager.userName.charAt(0).toUpperCase() : "P"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 28
                            }
                        }

                        ColumnLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignHCenter

                            Label {
                                text: sessionManager.userName || "Profesor"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignHCenter
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }
                            Label {
                                text: "Profesor"
                                color: Theme.textMuted
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.surfaceDark
                }

                // Menu Items - CORREGIDO: Manejo de navegación
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    spacing: 5

                    Repeater {
                        model: ListModel {
                            ListElement { icon: "📊"; label: "Dashboard"; page: "" }
                            ListElement { icon: "📚"; label: "Mis Cursos"; page: "CoursesPage.qml" }
                            ListElement { icon: "✅"; label: "Asistencia"; page: "AttendancePage.qml" }
                            ListElement { icon: "📝"; label: "Actividades"; page: "ActivityManagementPage.qml" }
                            ListElement { icon: "📊"; label: "Planilla de notas"; page: "PlanillaNotasPage.qml" }
                            ListElement { icon: "📄"; label: "Reportes"; page: "ReportsPage.qml" }
                            ListElement { icon: "📚"; label: "Material de estudio"; page: "MaterialPage.qml" }
                            ListElement { icon: "🕘"; label: "Mi horario"; page: "MiHorarioPage.qml" }
                            ListElement { icon: "👤"; label: "Mi perfil"; page: "PerfilPage.qml" }
                        }
                        
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: {
                                if (menuMouseArea.containsMouse) return index === 0 ? Theme.surfaceDark : Theme.surfaceDark
                                return index === 0 ? Theme.surfaceDark : "transparent"
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                spacing: 15

                                Label {
                                    text: icon
                                    font.pixelSize: 20
                                }

                                Label {
                                    text: label
                                    color: "white"
                                    font.bold: index === 0
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: menuMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    navDrawer.close()
                                    if (page !== "") {
                                        root.stackView.push(page)
                                    }
                                }
                            }
                            
                            // Active indicator strip
                            Rectangle {
                                visible: index === 0
                                width: 4
                                height: parent.height
                                color: primaryColor
                                anchors.left: parent.left
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Logout Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: Theme.dangerDark

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Label { text: "🚪"; font.pixelSize: 20 }
                        Label { 
                            text: "Cerrar Sesión"
                            color: "white"
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: sessionManager.clear()
                    }
                }
            }
        }
    }

    // Main Content Area
    ScrollView {
        id: mainScroll
        anchors.fill: parent
        clip: true
        // El ancho del contenido se fija al disponible: antes dependía de su propio
        // ancho implícito (bucle de layout) y el panel ocupaba solo ~600 px.
        contentWidth: availableWidth

        ColumnLayout {
            width: Math.min(mainScroll.availableWidth - 2 * Theme.spacingXl, Theme.maxContentWidth)
            x: (mainScroll.availableWidth - width) / 2
            y: Theme.spacingL
            spacing: Theme.spacingL

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                ToolButton {
                    text: "☰"
                    font.pixelSize: 24
                    onClicked: navDrawer.open()
                    
                    background: Rectangle {
                        color: "white"
                        radius: 8
                        border.color: Theme.border
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Label {
                        text: "Hola, " + (sessionManager.userName || "Profesor")
                        font.bold: true
                        font.pixelSize: 24
                        color: textColor
                    }
                    Label {
                        text: "Bienvenido a tu panel de control"
                        font.pixelSize: 14
                        color: Theme.textSecondary
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Refresh Button
                Button {
                    text: "↻ Actualizar"
                    flat: true
                    onClicked: {
                        profesorViewModel.loadDashboard()
                        profesorViewModel.loadMaterias()
                        profesorViewModel.loadCursos()
                    }
                }

                // Menú de usuario (Mi perfil / Cerrar sesión), igual que en el resto de pantallas
                UserChip {}
            }

            // Aviso cuando el profesor aún no tiene materias/cursos asignados: antes el panel
            // aparecía vacío y con todo a 0 sin explicar el motivo.
            Rectangle {
                Layout.fillWidth: true
                visible: materiaCombo.count === 0 && !profesorViewModel.isLoading
                implicitHeight: avisoAsignacion.implicitHeight + 2 * Theme.spacingM
                radius: Theme.radiusM
                color: Theme.warningSoft
                border.color: Theme.warning

                RowLayout {
                    id: avisoAsignacion
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM
                    Label { text: "\u26A0\uFE0F"; font.pixelSize: 22 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: qsTr("Aún no tienes materias asignadas")
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: Theme.textSecondary
                            text: qsTr("Pide al administrador que te asigne materias y cursos (Panel web › Académico › Asignaciones). Después pulsa «Actualizar».")
                        }
                    }
                }
            }

            // Stats Grid - CORREGIDO: Layout mejorado
            GridLayout {
                columns: root.width < 800 ? 1 : 3
                rowSpacing: 15
                columnSpacing: 15
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width

                StatCard {
                    title: "Estudiantes Totales"
                    value: profesorViewModel.totalEstudiantes || 0
                    icon: "👥"
                    color: Theme.primary
                }

                StatCard {
                    title: "Actividades Activas"
                    value: profesorViewModel.actividadesActivas || 0
                    icon: "📝"
                    color: Theme.success
                }

                StatCard {
                    title: "Entregas Pendientes"
                    value: profesorViewModel.entregasPendientes || 0
                    icon: "⚠️"
                    color: Theme.warning
                }
            }

            // Main Action Area: Create Activity - CORREGIDO: Model binding
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: createActivityColumn.implicitHeight + 40
                color: "white"
                radius: 12
                
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: createActivityColumn
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 20

                    Label {
                        text: "Crear Nueva Actividad"
                        font.bold: true
                        font.pixelSize: 18
                        color: textColor
                    }

                    // Selectors Row - CORREGIDO: Binding mejorado
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        // Materia Selector
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label { text: "Materia"; font.bold: true; color: Theme.textSecondary }
                            ComboBox {
                                id: materiaCombo
                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                model: profesorViewModel.materiaModel
                                textRole: "nombre"
                                displayText: currentIndex >= 0 ? currentText : "Seleccione materia..."
                                
                                background: Rectangle {
                                    color: Theme.surfaceAlt
                                    border.color: Theme.border
                                    radius: 6
                                }
                                
                                onCountChanged: {
                                    if (count > 0 && currentIndex === -1) currentIndex = 0
                                    console.log("MateriaCombo count:", count)
                                }
                                delegate: ItemDelegate {
                                    width: materiaCombo.width
                                    contentItem: Text {
                                        text: model.nombre
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    highlighted: materiaCombo.highlightedIndex === index
                                }
                                

                                onActivated: refreshActividades()
                                onCurrentIndexChanged: refreshActividades()
                            }
                        }

                        // Curso Selector
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label { text: "Curso"; font.bold: true; color: Theme.textSecondary }
                            ComboBox {
                                id: cursoCombo
                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                model: profesorViewModel.cursoModel
                                textRole: "nombre"
                                displayText: currentIndex >= 0 ? currentText : "Seleccione curso..."
                                
                                background: Rectangle {
                                    color: Theme.surfaceAlt
                                    border.color: Theme.border
                                    radius: 6
                                }
                                
                                onCountChanged: {
                                    if (count > 0 && currentIndex === -1) currentIndex = 0
                                    console.log("CursoCombo count:", count)
                                }
                                delegate: ItemDelegate {
                                    width: cursoCombo.width
                                    contentItem: Text {
                                        text: model.nombre
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    highlighted: cursoCombo.highlightedIndex === index
                                }


                                onActivated: refreshActividades()
                                onCurrentIndexChanged: refreshActividades()
                            }
                        }
                    }

                    // Form Grid - CORREGIDO: Validación mejorada
                    GridLayout {
                        columns: root.width < 600 ? 1 : 2
                        columnSpacing: 20
                        rowSpacing: 15
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label { text: "Tipo de Actividad"; font.bold: true; color: Theme.textSecondary }
                            ComboBox {
                                id: tipoCombo
                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                model: ["EXAMEN", "QUIZ", "TALLER"]
                                currentIndex: 0
                                background: Rectangle {
                                    color: Theme.surfaceAlt
                                    border.color: Theme.border
                                    radius: 6
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label { text: "Título"; font.bold: true; color: Theme.textSecondary }
                            TextField {
                                id: tituloField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                placeholderText: "Ej: Parcial Corte 1"
                                background: Rectangle {
                                    color: Theme.surfaceAlt
                                    border.color: Theme.border
                                    radius: 6
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label { text: "Fecha Límite"; font.bold: true; color: Theme.textSecondary }
                            
                            Button {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                text: datePickerPopup.selectedDate ? 
                                      datePickerPopup.selectedDate.toLocaleDateString(Qt.locale(), "dd/MM/yyyy") : 
                                      "Seleccionar fecha..."
                                onClicked: datePickerPopup.open()
                                
                                background: Rectangle {
                                    color: Theme.surfaceAlt
                                    border.color: Theme.border
                                    radius: 6
                                }
                                
                                contentItem: Label {
                                    text: parent.text
                                    color: datePickerPopup.selectedDate ? textColor : Theme.textMuted
                                    horizontalAlignment: Text.AlignLeft
                                    leftPadding: 10
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label { text: "Duración (min)"; font.bold: true; color: Theme.textSecondary }
                            TextField {
                                id: duracionField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                placeholderText: "60"
                                text: "60"
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 1; top: 9999 }
                                background: Rectangle {
                                    color: Theme.surfaceAlt
                                    border.color: Theme.border
                                    radius: 6
                                }
                            }
                        }
                    }

                    // Submit Button - CORREGIDO: Validación
                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        Layout.topMargin: 10
                        
                        background: Rectangle {
                            color: parent.enabled ? (parent.pressed ? Theme.primaryDark : primaryColor) : Theme.textMuted
                            radius: 8
                        }
                        
                        contentItem: RowLayout {
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label { text: "🚀"; font.pixelSize: 16 }
                            Label { 
                                text: "Crear Actividad"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 16
                            }
                        }
                        
                        enabled: tituloField.text && datePickerPopup.selectedDate && duracionField.text && 
                                materiaCombo.currentIndex >= 0 && cursoCombo.currentIndex >= 0
                        
                        onClicked: {
                            var materiaId = profesorViewModel.materiaModel.get(materiaCombo.currentIndex).id
                            var cursoId = profesorViewModel.cursoModel.get(cursoCombo.currentIndex).id
                            
                            var d = datePickerPopup.selectedDate
                            var isoDate = d.getFullYear() + "-" + 
                                          ("0" + (d.getMonth() + 1)).slice(-2) + "-" + 
                                          ("0" + d.getDate()).slice(-2)
                            
                            profesorViewModel.createActividad(
                                tituloField.text,
                                tipoCombo.currentText,
                                "",  // descripcion
                                isoDate,
                                parseInt(duracionField.text),
                                materiaId,
                                cursoId
                            )
                            
                            // Reset fields
                            tituloField.clear()
                            duracionField.text = "60"
                            datePickerPopup.selectedDate = null
                            tipoCombo.currentIndex = 0
                        }
                    }
                }
            }

            // Current Activities List - CORREGIDO: Manejo de modelo vacío
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 500
                color: "white"
                radius: 12
                
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Actividades del Curso"
                            font.bold: true
                            font.pixelSize: 18
                            color: textColor
                        }
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "Editar Preguntas"
                            flat: true
                            icon.name: "edit-entry" // fallback
                            visible: profesorViewModel.actividadModel.count > 0
                            onClicked: stackView.push("ActivityManagementPage.qml")
                        }
                    }

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        color: Theme.surfaceAlt
                        radius: 6

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 10
                            
                            Label { Layout.fillWidth: true; text: "ACTIVIDAD"; font.bold: true; font.pixelSize: 12; color: Theme.textMuted }
                            Label { Layout.preferredWidth: 80; text: "TIPO"; font.bold: true; font.pixelSize: 12; color: Theme.textMuted }
                            Label { Layout.preferredWidth: 100; text: "ENTREGA"; font.bold: true; font.pixelSize: 12; color: Theme.textMuted }
                            Label { Layout.preferredWidth: 80; text: "TIEMPO"; font.bold: true; font.pixelSize: 12; color: Theme.textMuted }
                            Label { Layout.preferredWidth: 40; text: ""; } // Action space
                        }
                    }

                    // Lista de actividades o mensaje vacío
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: profesorViewModel.actividadModel.count > 0 ? listViewComponent : emptyComponent
                    }
                }
            }
        }
    }

    // Componentes para la lista de actividades
    Component {
        id: listViewComponent
        ListView {
            id: actividadesTable
            clip: true
            model: profesorViewModel.actividadModel
            spacing: 8

            delegate: Rectangle {
                width: actividadesTable.width
                height: 60
                color: "white"
                radius: 8
                border.color: Theme.surfaceAlt
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: tipo === "EXAMEN" ? Theme.successSoft : 
                               tipo === "QUIZ" ? Theme.warningSoft : 
                               tipo === "TALLER" ? Theme.primarySoft : Theme.primarySoft
                        Label { 
                            anchors.centerIn: parent
                            text: tipo === "EXAMEN" ? "📝" : 
                                  tipo === "QUIZ" ? "❓" : 
                                  tipo === "TALLER" ? "🔧" : "📄"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { 
                            text: titulo || "Sin Título"
                            font.bold: true
                            color: textColor
                            elide: Text.ElideRight
                        }
                        Label {
                            text: materia || ""
                            font.pixelSize: 11
                            color: Theme.textMuted
                            elide: Text.ElideRight
                        }
                    }

                    Label {
                        Layout.preferredWidth: 100
                        text: tipo || ""
                        color: Theme.primary
                        font.bold: true
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.preferredWidth: 100
                        text: fechaEntrega ? fechaEntrega.split('T')[0] : "--/--/----"
                        color: Theme.textSecondary
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.preferredWidth: 80
                        text: (duracion || "0") + " min"
                        color: Theme.textSecondary
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    
                    Button {
                        Layout.preferredWidth: 40
                        text: "✏️"
                        flat: true
                        enabled: root.stackView !== null
                        onClicked: {
                            if (root.stackView) {
                                root.stackView.push("QuestionEditorPage.qml", { actividadId: id, actividadTitulo: titulo })
                            }
                        }
                        ToolTip.visible: hovered
                        ToolTip.text: "Editar Preguntas"
                    }
                }
            }
        }
    }

    Component {
        id: emptyComponent
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            
            Label {
                text: "📋"
                font.pixelSize: 48
                Layout.alignment: Qt.AlignHCenter
            }
            
            Label {
                text: "No hay actividades creadas"
                color: Theme.textMuted
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }
            
            Label {
                text: "Selecciona una materia y curso para ver las actividades"
                color: Theme.textMuted
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // Modal Date Picker (Simple implementation)
    Popup {
        id: datePickerPopup
        anchors.centerIn: parent
        width: 320
        height: 380
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var selectedDate: null

        background: Rectangle {
            color: "white"
            radius: 12
            border.color: Theme.border
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            
            Label {
                text: "Seleccionar Fecha"
                font.bold: true
                font.pixelSize: 18
                color: textColor
                Layout.alignment: Qt.AlignHCenter
            }

            DatePicker {
                id: datePicker
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                onDateSelected: (date) => {
                    datePickerPopup.selectedDate = date
                    datePickerPopup.close()
                }
            }
            
            Button {
                text: "Cancelar"
                Layout.fillWidth: true
                onClicked: datePickerPopup.close()
            }
        }
    }
}
