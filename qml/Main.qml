import QtQuick
import QtQuick.Controls
import "pages"

ApplicationWindow {
    id: window
    visible: true
    width: 600
    height: 800
    title: "Rep Client"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: sessionManager.isAuthenticated ? dashboardComponent : loginComponent
    }

    Component {
        id: loginComponent
        LoginPage {
            onLoginSuccess: {
                if (sessionManager.userRole === "ESTUDIANTE") {
                    stackView.replace(dashboardComponent)
                } else {
                    console.log("Rol no soportado en esta vista aún: " + sessionManager.userRole)
                }
            }
        }
    }

    Component {
        id: dashboardComponent
        StudentDashboard {}
    }

    Connections {
        target: sessionManager
        function onSessionChanged() {
            if (!sessionManager.isAuthenticated) {
                stackView.replace(loginComponent)
            }
        }
    }
}
