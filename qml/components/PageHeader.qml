import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

/*
 * Cabecera estándar de página: botón volver, título/subtítulo, acciones a la
 * derecha (slot "actions") y chip de usuario con cierre de sesión.
 */
ToolBar {
    id: header
    property string title: ""
    property string subtitle: ""
    property bool showBack: true
    property bool showUser: true
    default property alias actions: actionsRow.data
    /** Teléfono: título más pequeño y sin chip de usuario (el menú está en la app móvil). */
    readonly property bool compacto: width < 600

    signal backClicked()

    implicitHeight: Theme.headerHeight
    background: Rectangle {
        color: Theme.surface
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.border
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingM

        ToolButton {
            visible: header.showBack
            text: "←"
            font.pixelSize: 22
            Accessible.name: qsTr("Volver")
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Volver")
            onClicked: {
                header.backClicked()
                const view = header.parent ? header.parent.StackView.view : null
                if (view && view.depth > 1)
                    view.pop()
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Label {
                text: header.title
                color: Theme.textPrimary
                font.pixelSize: header.compacto ? Theme.fontSubtitle : Theme.fontTitle
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                visible: header.subtitle !== ""
                text: header.subtitle
                color: Theme.textSecondary
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        RowLayout {
            id: actionsRow
            spacing: Theme.spacingS
        }

        UserChip {
            visible: header.showUser && sessionManager.isAuthenticated && !header.compacto
        }
    }
}
