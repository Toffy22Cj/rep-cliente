import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    title: "Mis Cursos"

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "\u2190"
                onClicked: stackView.pop()
            }
            Label {
                text: "Mis Cursos"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
        }
    }

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
                border.color: "#ecf0f1"
                border.width: 1
            }

            contentItem: RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                
                Rectangle {
                    width: 50
                    height: 50
                    radius: 25
                    color: "#3498db"
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
                        color: "#7f8c8d"
                    }
                }
                
                Button {
                    text: "Ver Estudiantes"
                    flat: true
                    // onClicked: stackView.push("StudentsPage.qml", { cursoId: model.id }) // Placeholder for future
                }
            }
        }
    }

    Component.onCompleted: {
        profesorViewModel.loadCursos()
    }
}
