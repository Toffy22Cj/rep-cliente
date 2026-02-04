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
        LoginPage {}
    }

    Component { id: studentDashboard; StudentDashboard {} }
    Component { id: teacherDashboard; TeacherDashboard {} }
    Component { id: adminDashboard; AdminDashboard {} }

    Component.onCompleted: {
        console.log("Main.qml Component.onCompleted iniciado")
        console.log("loginViewModel definido:", loginViewModel !== undefined)
        console.log("sessionManager definido:", sessionManager !== undefined)
        
        if (loginViewModel !== undefined) {
            loginViewModel.loginSuccess.connect(handleLoginSuccess)
            console.log("✓ Conexión establecida: loginViewModel.loginSuccess")
        } else {
            console.error("❌ loginViewModel no está disponible en Main.qml")
        }
        
        if (sessionManager !== undefined) {
            sessionManager.sessionChanged.connect(handleSessionChanged)
            console.log("✓ Conexión establecida: sessionManager.sessionChanged")
        } else {
            console.error("❌ sessionManager no está disponible en Main.qml")
        }
    }
    
    function handleLoginSuccess(role) {
        console.log("Main.qml: Login OK, rol:", role)
        stackView.replace(getDashboardComponent())
    }
    
    function handleSessionChanged() {
        console.log("Main.qml: Session changed")
        if (!sessionManager.isAuthenticated) {
            stackView.replace(loginComponent)
        }
    }
}
