import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

// Avatar con nombre y rol del usuario; al pulsarlo ofrece cerrar sesión.
ItemDelegate {
    id: chip
    implicitHeight: 44
    padding: Theme.spacingXs
    leftPadding: Theme.spacingS
    rightPadding: Theme.spacingS
    hoverEnabled: true
    Accessible.name: qsTr("Menú de usuario")

    background: Rectangle {
        radius: Theme.radiusL
        color: chip.hovered ? Theme.surfaceAlt : "transparent"
        border.color: chip.hovered ? Theme.border : "transparent"
    }

    contentItem: RowLayout {
        spacing: Theme.spacingS
        Avatar {
            text: sessionManager.userInitials
            size: 32
        }
        ColumnLayout {
            spacing: 0
            Label {
                text: sessionManager.userFullName
                color: Theme.textPrimary
                font.pixelSize: Theme.fontBody
                font.weight: Font.Medium
            }
            Label {
                text: roleLabel(sessionManager.userRole)
                color: Theme.textSecondary
                font.pixelSize: Theme.fontCaption
            }
        }
    }

    function roleLabel(role) {
        if (role === "ADMIN") return qsTr("Administrador")
        if (role === "PROFESOR") return qsTr("Profesor")
        return qsTr("Estudiante")
    }

    onClicked: menu.open()

    Menu {
        id: menu
        y: chip.height
        MenuItem {
            text: qsTr("Mi perfil")
            onTriggered: {
                stackView.push("pages/PerfilPage.qml")
            }
        }
        MenuItem {
            text: qsTr("Cerrar sesión")
            onTriggered: sessionManager.clear()
        }
    }
}
