import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Page {
    id: root
    background: Rectangle { color: "#f4f6f9" }
    property var stackView: StackView.view

    Component.onCompleted: {
        console.log("Admin Dashboard Loaded")
    }

    header: ToolBar {
        background: Rectangle { color: "#2c3e50" }
        RowLayout {
            anchors.fill: parent
            spacing: 15
            ToolButton {
                text: "Cerrar Sesión"
                icon.source: "" // Clear icon if default exists
                font.bold: true
                onClicked: sessionManager.clear()
                contentItem: Text {
                    text: "Cerrar Sesión"
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#c0392b" : "transparent"
                    radius: 4
                }
            }
            Label {
                text: "Panel de Administrador"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
            Label {
                text: sessionManager.userName
                color: "#ecf0f1"
            }
        }
    }

    GridLayout {
        anchors.centerIn: parent
        columns: 2
        rowSpacing: 20
        columnSpacing: 20
        width: Math.min(parent.width - 40, 800)

        // Management Cards
        Repeater {
            model: [
                { title: "Usuarios", icon: "👥", page: "UserManagementPage.qml", color: "#3498db" },
                { title: "Cursos", icon: "📚", page: "CourseManagementPage.qml", color: "#e67e22" },
                { title: "Materias", icon: "📖", page: "SubjectManagementPage.qml", color: "#9b59b6" },
                { title: "Configuración", icon: "⚙️", page: "", color: "#7f8c8d" }
            ]

            delegate: Rectangle {
                id: card
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                radius: 12
                color: "white"
                
                border.color: "#ecf0f1"
                border.width: 1

                // Hover effect
                scale: mouseArea.containsMouse ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 200 } }
                
                // Color change on hover not strictly needed if we have scale, but can add if desired
                // color: mouseArea.containsMouse ? "#fdfdfd" : "white"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 60; height: 60; radius: 30
                        color: modelData.color
                        Label {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: 30
                        }
                    }
                    
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.title
                        font.bold: true
                        font.pixelSize: 18
                        color: "#2c3e50"
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.page !== "") {
                            stackView.push(modelData.page)
                        }
                    }
                }
            }
        }
    }
}
