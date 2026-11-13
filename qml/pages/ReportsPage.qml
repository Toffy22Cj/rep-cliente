import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    title: "Reportes"
    background: Rectangle { color: Theme.background }

    property var stackView: StackView.view
    property color primaryColor: Theme.primary

    Component.onCompleted: {
        profesorViewModel.loadMaterias()
        profesorViewModel.loadCursos()
    }

    header: PageHeader { title: "Reportes y Estadísticas" }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        TabBar {
            id: reportTabs
            Layout.fillWidth: true
            
            background: Rectangle { color: Theme.surface; radius: Theme.radiusM }
            AppTabButton { text: qsTr("Promedios por curso") }
            AppTabButton { text: qsTr("Estadísticas de actividad") }
        }

        StackLayout {
            currentIndex: reportTabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            // --- TAB 1: PROMEDIOS ---
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    // Filters
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        color: "white"
                        radius: 8
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 20

                            ColumnLayout {
                                Label { text: "Materia"; font.bold: true; color: Theme.textSecondary }
                                ComboBox {
                                    id: materiaCombo
                                    model: profesorViewModel.materiaModel
                                    textRole: "nombre"
                                    Layout.preferredWidth: 200
                                    onActivated: loadPromedios()
                                }
                            }

                            ColumnLayout {
                                Label { text: "Curso"; font.bold: true; color: Theme.textSecondary }
                                ComboBox {
                                    id: cursoCombo
                                    model: profesorViewModel.cursoModel
                                    textRole: "nombre"
                                    Layout.preferredWidth: 150
                                    onActivated: loadPromedios()
                                }
                            }

                            Button {
                                text: "🔍 Generar"
                                highlighted: true
                                Layout.alignment: Qt.AlignBottom
                                onClicked: loadPromedios()
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: "💾 Exportar PDF"
                                enabled: reportsViewModel.promediosModel.count > 0
                                onClicked: {
                                    var mId = profesorViewModel.materiaModel.get(materiaCombo.currentIndex).id
                                    var cId = profesorViewModel.cursoModel.get(cursoCombo.currentIndex).id
                                    reportsViewModel.exportarPromedios(cId, mId)
                                }
                            }
                        }
                    }

                    // Results Table
                    ListView {
                        id: promediosList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: reportsViewModel.promediosModel
                        spacing: 5

                        header: Rectangle {
                            width: parent.width
                            height: 40
                            color: Theme.border
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                Label { text: "ESTUDIANTE"; Layout.fillWidth: true; font.bold: true }
                                Label { text: "PROMEDIO"; Layout.preferredWidth: 100; font.bold: true; horizontalAlignment: Text.AlignRight }
                            }
                        }

                        delegate: Rectangle {
                            width: promediosList.width
                            height: 50
                            color: "white"
                            radius: 5
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                Label { text: model.nombre; Layout.fillWidth: true; font.pixelSize: 16 }
                                Rectangle {
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 30
                                    radius: 15
                                    color: model.promedio >= 3.0 ? Theme.success : Theme.danger
                                    Label {
                                        anchors.centerIn: parent
                                        text: model.promedio.toFixed(1)
                                        color: "white"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- TAB 2: ESTADÍSTICAS ---
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    // Filters
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        color: "white"
                        radius: 8
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 20

                            ColumnLayout {
                                Label { text: "Materia"; font.bold: true; color: Theme.textSecondary }
                                ComboBox {
                                    id: statMateriaCombo
                                    model: profesorViewModel.materiaModel
                                    textRole: "nombre"
                                    Layout.preferredWidth: 200
                                    onActivated: loadActividades()
                                }
                            }

                            ColumnLayout {
                                Label { text: "Curso"; font.bold: true; color: Theme.textSecondary }
                                ComboBox {
                                    id: statCursoCombo
                                    model: profesorViewModel.cursoModel
                                    textRole: "nombre"
                                    Layout.preferredWidth: 150
                                    onActivated: loadActividades()
                                }
                            }
                            
                            ColumnLayout {
                                Label { text: "Actividad"; font.bold: true; color: Theme.textSecondary }
                                ComboBox {
                                    id: actividadCombo
                                    model: profesorViewModel.actividadModel
                                    textRole: "titulo"
                                    Layout.preferredWidth: 250
                                    onActivated: loadStats()
                                }
                            }
                        }
                    }

                    // Stats Cards
                    GridLayout {
                        columns: 4
                        Layout.fillWidth: true
                        columnSpacing: 15
                        
                        StatCard { 
                            title: "Promedio"
                            value: reportsViewModel.statPromedio.toFixed(1)
                            icon: "📊"
                            color: Theme.primary
                            Layout.fillWidth: true
                        }
                         StatCard { 
                            title: "Nota Máxima"
                            value: reportsViewModel.statMaxima.toFixed(1)
                            icon: "🏆"
                            color: Theme.success
                            Layout.fillWidth: true
                        }
                         StatCard { 
                            title: "Nota Mínima"
                            value: reportsViewModel.statMinima.toFixed(1)
                            icon: "⚠️"
                            color: Theme.danger
                            Layout.fillWidth: true
                        }
                         StatCard { 
                            title: "Entregas"
                            value: reportsViewModel.statTotalEntregas + "/" + reportsViewModel.statTotalEstudiantes
                            icon: "📥"
                            color: Theme.warning
                            Layout.fillWidth: true
                        }
                    }
                    
                    Button {
                        text: "📝 Ir a Calificar Entregas"
                        Layout.alignment: Qt.AlignRight
                        highlighted: true
                        enabled: actividadCombo.currentIndex >= 0
                        onClicked: {
                            var actData = profesorViewModel.actividadModel.get(actividadCombo.currentIndex)
                            stackView.push("GradingPage.qml", { 
                                actividadId: actData.id,
                                actividadTitulo: actData.titulo 
                            })
                        }
                    }
                    
                    // Detailed List
                    ListView {
                        id: entregasList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: reportsViewModel.entregasModel
                        spacing: 5
                        
                         header: Rectangle {
                            width: parent.width
                            height: 40
                            color: Theme.border
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                Label { text: "ESTUDIANTE"; Layout.fillWidth: true; font.bold: true }
                                Label { text: "ESTADO"; Layout.preferredWidth: 100; font.bold: true }
                                Label { text: "FECHA"; Layout.preferredWidth: 150; font.bold: true }
                            }
                        }
                        
                        delegate: Rectangle {
                            width: entregasList.width
                            height: 50
                            color: "white"
                            radius: 5
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                Label { text: model.estudiante; Layout.fillWidth: true }
                                Label { 
                                    text: model.estado
                                    color: model.estado === "ENTREGADO" ? Theme.success : Theme.danger
                                    font.bold: true 
                                    Layout.preferredWidth: 100
                                }
                                Label { text: model.fecha; Layout.preferredWidth: 150 }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Notifications
    Connections {
        target: reportsViewModel
        function onExportCompleted(path) {
            console.log("Export complete:", path)
            // Show toast or dialog
        }
        function onErrorOccurred(error) {
            console.error("Report error:", error)
        }
    }

    function loadPromedios() {
        if (materiaCombo.currentIndex >= 0 && cursoCombo.currentIndex >= 0) {
            var mId = profesorViewModel.materiaModel.get(materiaCombo.currentIndex).id
            var cId = profesorViewModel.cursoModel.get(cursoCombo.currentIndex).id
            reportsViewModel.loadPromedios(cId, mId)
        }
    }

    function loadActividades() {
        if (statMateriaCombo.currentIndex >= 0 && statCursoCombo.currentIndex >= 0) {
            var mId = profesorViewModel.materiaModel.get(statMateriaCombo.currentIndex).id
            var cId = profesorViewModel.cursoModel.get(statCursoCombo.currentIndex).id
            profesorViewModel.loadActividades(mId, cId)
        }
    }
    
    function loadStats() {
        if (actividadCombo.currentIndex >= 0) {
             // Safe access to model data
             // Note: QAbstractListModel access in JS can be tricky, assuming 'get' method exists or using index
             var actId = profesorViewModel.actividadModel.get(actividadCombo.currentIndex).id
             reportsViewModel.loadEstadisticas(actId)
             reportsViewModel.loadEntregas(actId)
        }
    }
}
