import QtQuick
import QtQuick.Controls
import Rep
import "pages"

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 820
    minimumWidth: 960
    minimumHeight: 640
    title: qsTr("REP · Gestión educativa")
    color: Theme.background
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody

    // Paleta global: todos los controles estándar (ComboBox, Switch, CheckBox,
    // RadioButton, SpinBox, menús...) heredan los colores del sistema de diseño.
    palette {
        window: Theme.background
        windowText: Theme.textPrimary
        base: Theme.surface
        alternateBase: Theme.surfaceAlt
        text: Theme.textPrimary
        button: Theme.surface
        buttonText: Theme.textPrimary
        brightText: Theme.textOnPrimary
        highlight: Theme.primary
        highlightedText: Theme.textOnPrimary
        light: Theme.surface
        midlight: Theme.border
        mid: Theme.borderStrong
        dark: Theme.primary
        shadow: Theme.textMuted
        placeholderText: Theme.textMuted
        toolTipBase: Theme.sidebar
        toolTipText: Theme.textOnDark
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: sessionManager.isAuthenticated ? dashboardFor(sessionManager.userRole) : loginComponent

        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal }
                NumberAnimation { property: "x"; from: 24; to: 0; duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }
        }
        pushExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast } }
        popEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal } }
        popExit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast }
                NumberAnimation { property: "x"; from: 0; to: 24; duration: Theme.animFast }
            }
        }
        replaceEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal } }
        replaceExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast } }
    }

    function dashboardFor(role) {
        if (role === "ESTUDIANTE") return studentDashboard
        if (role === "PROFESOR") return teacherDashboard
        if (role === "ADMIN") return adminDashboard
        return loginComponent
    }

    Component {
        id: loginComponent
        LoginPage {
            onLoginSuccess: {
                const dash = dashboardFor(sessionManager.userRole)
                if (dash !== loginComponent)
                    stackView.replace(null, dash)
            }
        }
    }

    Component { id: studentDashboard; StudentDashboard {} }
    Component { id: teacherDashboard; TeacherDashboard {} }
    Component { id: adminDashboard; AdminDashboard {} }

    // Cierre de sesión (manual o por token expirado): volver al login vaciando la pila
    Connections {
        target: sessionManager
        function onSessionChanged() {
            if (!sessionManager.isAuthenticated)
                stackView.replace(null, loginComponent)
        }
    }
}
