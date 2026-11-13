import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    title: "Estudiantes del Curso"
    
    property int cursoId: 0
    property string cursoNombre: ""
    
    ListModel { id: studentsModel }
    
    header: PageHeader {
        title: qsTr("Estudiantes · %1").arg(root.cursoNombre || root.cursoId)
        AppButton {
            text: qsTr("⬇ Exportar CSV")
            variant: "secondary"
            enabled: root.cursoId > 0
            onClicked: api.abrir("/api/profesor/estudiantes/curso/" + root.cursoId + "/export")
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        Label {
            text: studentsModel.count + " estudiantes registrados"
            font.pixelSize: 14
            color: Theme.textSecondary
        }
        
        ListView {
            id: studentsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: studentsModel
            spacing: 10
            clip: true
            
            delegate: ItemDelegate {
                width: studentsList.width
                height: 70
                background: Rectangle {
                    color: "white"
                    radius: 8
                    border.color: Theme.border
                }
                
                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: Theme.primary
                        Label {
                            anchors.centerIn: parent
                            text: model.nombre ? model.nombre.charAt(0).toUpperCase() : "E"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 18
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: model.nombre || "Sin nombre"
                            font.bold: true
                            font.pixelSize: 16
                        }
                        Label {
                            text: "ID: " + (model.identificacion || "N/A")
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }
                        Label {
                            text: model.correo || ""
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }
                    }
                }
            }
            
            Label {
                visible: studentsModel.count === 0
                anchors.centerIn: parent
                text: "No hay estudiantes registrados en este curso"
                color: Theme.textMuted
                font.pixelSize: 16
            }
        }
    }
    
    Connections {
        target: profesorViewModel
        function onEstudiantesFetched(estudiantes) {
            console.log("StudentsPage: Estudiantes recibidos:", estudiantes.length)
            studentsModel.clear()
            for (let i = 0; i < estudiantes.length; i++) {
                studentsModel.append(estudiantes[i])
            }
        }
    }
    
    Component.onCompleted: {
        if (cursoId > 0) {
            profesorViewModel.loadEstudiantes(cursoId)
        } else {
            console.warn("StudentsPage: cursoId no válido")
        }
    }
}
