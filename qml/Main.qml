import QtQuick
import QtQuick.Controls
import "pages"

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 800
    title: "Rep Client"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: sessionManager.isAuthenticated ? getDashboardComponent() : loginComponent
    }

    function getDashboardComponent() {
        if (sessionManager.userRole === "ESTUDIANTE") return studentDashboard
        if (sessionManager.userRole === "PROFESOR") return teacherDashboard
        if (sessionManager.userRole === "ADMIN") return adminDashboard
        return loginComponent
    }

    Component {
        id: loginComponent
        LoginPage {
            onLoginSuccess: {
                var dash = getDashboardComponent()
                console.log("Login success, redirecting to: " + sessionManager.userRole)
                if (dash !== loginComponent) {
                    stackView.replace(dash)
                } else {
                    console.error("Rol desconocido: " + sessionManager.userRole)
                }
            }
        }
    }

    Component { id: studentDashboard; StudentDashboard {} }
    Component { id: teacherDashboard; TeacherDashboard {} }
    Component { id: adminDashboard; AdminDashboard {} }

    Connections {
        target: sessionManager
        function onSessionChanged() {
            if (!sessionManager.isAuthenticated) {
                stackView.replace(loginComponent)
            }
        }
    }
}
