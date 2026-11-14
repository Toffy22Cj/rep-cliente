import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    property var stackView: StackView.view
    background: Rectangle { color: Theme.background }

    header: PageHeader {
        title: qsTr("Panel de administración")
        subtitle: qsTr("Gestione usuarios, cursos, materias y asignaciones")
        showBack: false
    }

    readonly property var modules: [
        { title: qsTr("Usuarios"), description: qsTr("Altas, edición, roles y estado de las cuentas"), icon: "👥", page: "UserManagementPage.qml", tint: Theme.primary },
        { title: qsTr("Cursos"), description: qsTr("Grados y grupos del colegio"), icon: "🏫", page: "CourseManagementPage.qml", tint: Theme.warning },
        { title: qsTr("Materias"), description: qsTr("Catálogo de asignaturas"), icon: "📖", page: "SubjectManagementPage.qml", tint: Theme.purple },
        { title: qsTr("Asignaciones"), description: qsTr("Profesor · materia · curso"), icon: "🔗", page: "AssignmentsManagementPage.qml", tint: Theme.teal },
        { title: qsTr("Horario de clases"), description: qsTr("Clases de cada curso por día y hora"), icon: "🕘", page: "HorarioPage.qml", tint: Theme.info },
        { title: qsTr("Periodos académicos"), description: qsTr("Fechas y porcentaje de cada periodo del año"), icon: "📅", page: "PeriodosPage.qml", tint: Theme.success }
    ]

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: Math.min(parent.width - 2 * Theme.spacingXl, Theme.maxContentWidth)
            x: (parent.width - width) / 2
            spacing: Theme.spacingL

            Item { Layout.preferredHeight: Theme.spacingS }

            Label {
                text: qsTr("Hola, %1").arg(sessionManager.userName)
                color: Theme.textPrimary
                font.pixelSize: Theme.fontHeadline
                font.weight: Font.Bold
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.width > 1100 ? 4 : (root.width > 700 ? 2 : 1)
                rowSpacing: Theme.spacingM
                columnSpacing: Theme.spacingM

                Repeater {
                    model: root.modules
                    delegate: Card {
                        id: card
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        hoverable: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Theme.spacingS

                            Rectangle {
                                width: 48; height: 48; radius: Theme.radiusM
                                color: Qt.rgba(card.modelData.tint.r, card.modelData.tint.g, card.modelData.tint.b, 0.12)
                                Label {
                                    anchors.centerIn: parent
                                    text: card.modelData.icon
                                    font.pixelSize: 24
                                }
                            }
                            Label {
                                text: card.modelData.title
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSubtitle
                                font.weight: Font.DemiBold
                                Layout.topMargin: Theme.spacingXs
                            }
                            Label {
                                text: card.modelData.description
                                color: Theme.textSecondary
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Item { Layout.fillHeight: true }
                            Label {
                                text: qsTr("Abrir →")
                                color: card.modelData.tint
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.Button
                            Accessible.name: card.modelData.title
                            onClicked: root.stackView.push(card.modelData.page)
                        }
                    }
                }
            }
        }
    }
}
