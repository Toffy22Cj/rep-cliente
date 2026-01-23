import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "\u2630"
                font.pixelSize: 20
                onClicked: navDrawer.open()
            }
            Label {
                text: "Panel del Profesor"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
            Label {
                text: sessionManager.userName
                color: "white"
                Layout.rightMargin: 10
            }
        }
    }

    Drawer {
        id: navDrawer
        width: 250
        height: root.height

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Label {
                text: "Navegación"
                font.bold: true
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                Layout.bottomMargin: 10
            }

            Button {
                text: "Dashboard"
                Layout.fillWidth: true
                flat: true
                onClicked: { navDrawer.close(); }
            }

            Button {
                text: "Gestión de Actividades"
                Layout.fillWidth: true
                flat: true
                onClicked: { 
                    navDrawer.close();
                    stackView.push("ActivityManagementPage.qml")
                }
            }

            Button {
                text: "Control de Asistencia"
                Layout.fillWidth: true
                flat: true
                onClicked: { 
                    navDrawer.close();
                    stackView.push("AttendancePage.qml")
                }
            }

            Item { Layout.fillHeight: true }

            Button {
                text: "Cerrar Sesión"
                Layout.fillWidth: true
                palette.buttonText: "red"
                onClicked: sessionManager.clear()
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: parent.width
            anchors.margins: 20
            spacing: 25

            Label {
                text: "¡Hola, " + sessionManager.userName + "!"
                font.pixelSize: 24
                font.bold: true
                color: "#2c3e50"
            }

            // Statistics Cards Grid
            GridLayout {
                columns: root.width > 600 ? 3 : 1
                rowSpacing: 15
                columnSpacing: 15
                Layout.fillWidth: true

                StatCard {
                    title: "Estudiantes"
                    value: profesorViewModel.totalEstudiantes
                    cardColor: "#3498db"
                    icon: "\uD83D\uDC65"
                }

                StatCard {
                    title: "Actividades Activas"
                    value: profesorViewModel.actividadesActivas
                    cardColor: "#2ecc71"
                    icon: "\uD83D\uDCDD"
                }

                StatCard {
                    title: "Pendientes de Calificar"
                    value: profesorViewModel.entregasPendientes
                    cardColor: "#e67e22"
                    icon: "\u23F3"
                }
            }

            Label {
                text: "Resumen de Actividades Recientes"
                font.pixelSize: 18
                font.bold: true
                Layout.topMargin: 10
            }

            ListView {
                id: recentActivitiesList
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                model: profesorViewModel.actividadModel
                spacing: 10
                interactive: false

                delegate: ActivityDelegate {
                    width: recentActivitiesList.width
                    onViewResults: stackView.push("GradingPage.qml", { actividadId: model.id })
                    onEdit: stackView.push("QuestionEditorPage.qml", { actividadId: model.id })
                }
            }

            Button {
                text: "+ Nueva Actividad"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                highlighted: true
                onClicked: stackView.push("ActivityManagementPage.qml", { createNew: true })
            }
        }
    }

    component StatCard : Rectangle {
        property string title: ""
        property var value: 0
        property string cardColor: "blue"
        property string icon: ""

        Layout.fillWidth: true
        height: 120
        color: "white"
        radius: 12
        border.color: "#ecf0f1"
        border.width: 1

        Rectangle {
            width: 5
            height: parent.height - 20
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: parent.cardColor
            radius: 2
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15
            
            Column {
                Layout.fillWidth: true
                Label { text: title; color: "#7f8c8d"; font.bold: true }
                Label { text: value; color: "#2c3e50"; font.pixelSize: 32; font.bold: true }
            }

            Label {
                text: icon
                font.pixelSize: 40
                opacity: 0.2
            }
        }
    }

    component ActivityDelegate : ItemDelegate {
        signal viewResults()
        signal edit()

        width: parent.width
        height: 80
        background: Rectangle {
            color: "white"
            border.color: "#ecf0f1"
            radius: 8
        }

        contentItem: RowLayout {
            spacing: 15
            Column {
                Layout.fillWidth: true
                Label { text: model.titulo; font.bold: true; font.pixelSize: 16 }
                Label { text: "Entrega: " + model.fechaEntrega; color: "#95a5a6"; font.pixelSize: 12 }
            }
            Button {
                text: "Calificar"
                flat: true
                onClicked: viewResults()
            }
            Button {
                text: "Editar"
                highlighted: true
                onClicked: edit()
            }
        }
    }


    Component.onCompleted: {
        profesorViewModel.loadDashboard();
    }
}
