import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    title: "Mis Cursos"

    header: PageHeader { title: "Mis Cursos" }

    ListView {
        id: courseList
        anchors.fill: parent
        anchors.margins: 20
        model: profesorViewModel.cursoModel
        spacing: 15
        clip: true

        delegate: ItemDelegate {
            width: courseList.width
            height: 80
            background: Rectangle {
                color: "white"
                radius: 8
                border.color: Theme.border
                border.width: 1
            }

            contentItem: RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                
                Rectangle {
                    width: 50
                    height: 50
                    radius: 25
                    color: Theme.primary
                    Label {
                        anchors.centerIn: parent
                        text: model.grado
                        color: "white"
                        font.bold: true
                        font.pixelSize: 20
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        text: model.nombre ? model.nombre : "Grado " + model.grado + " - " + model.grupo
                        font.bold: true
                        font.pixelSize: 16
                    }
                    Label {
                        text: "Grupo: " + model.grupo
                        color: Theme.textSecondary
                    }
                }
                
                Button {
                    text: "Ver Estudiantes"
                    flat: true
                    onClicked: {
                        var cursoNombre = model.nombre || ("Grado " + model.grado + " - " + model.grupo)
                        stackView.push("StudentsPage.qml", { 
                            cursoId: model.id,
                            cursoNombre: cursoNombre
                        })
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        profesorViewModel.loadCursos()
    }
}
