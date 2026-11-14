import QtQuick
import QtQuick.Controls
import Rep
import "../components"
import "../pages"

/*
 * Aplicación móvil (Android): estudiante y profesor. Comparte con el escritorio la red,
 * la sesión, la caché sin conexión, la cola de envíos y el descubrimiento del servidor.
 * La administración se hace desde el escritorio o el panel web.
 */
ApplicationWindow {
    id: window
    visible: true
    width: 400
    height: 820
    title: qsTr("REP")
    color: Theme.background
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody

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
    }

    // Botón «Atrás» de Android: vuelve en la pila antes de cerrar la app
    onClosing: cierre => {
        if (stackView.depth > 1) {
            cierre.accepted = false
            stackView.pop()
        }
    }

    BannerConexion {
        id: bannerConexion
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 10
    }

    Toast { id: toastGlobal }

    Connections {
        target: descubrimiento
        function onReconectado(nombre, url) { toastGlobal.mostrar(qsTr("Servidor «%1» encontrado").arg(nombre), "exito") }
    }
    Connections {
        target: sincronizacion
        function onEnvioCompletado(descripcion, respuesta) { toastGlobal.mostrar(qsTr("Sincronizado: %1").arg(descripcion), "exito") }
        function onEnvioRechazado(descripcion, mensaje) { toastGlobal.mostrar(qsTr("No se pudo enviar «%1»: %2").arg(descripcion).arg(mensaje), "error") }
    }

    function inicio() {
        if (!sessionManager.isAuthenticated) return loginComponent
        if (sessionManager.debeCambiarContrasena) return perfilObligatorio
        if (sessionManager.userRole === "ESTUDIANTE") return shellEstudiante
        if (sessionManager.userRole === "PROFESOR") return shellProfesor
        return soloEscritorio
    }

    StackView {
        id: stackView
        anchors.top: bannerConexion.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        initialItem: window.inicio()
    }

    Component { id: loginComponent; LoginMovil { onLoginSuccess: stackView.replace(null, window.inicio()) } }
    Component { id: shellEstudiante; ShellMovil { rol: "ESTUDIANTE" } }
    Component { id: shellProfesor; ShellMovil { rol: "PROFESOR" } }
    Component { id: perfilObligatorio; PerfilPage { obligatorio: true } }
    Component {
        id: soloEscritorio
        Page {
            background: Rectangle { color: Theme.background }
            EmptyState {
                anchors.centerIn: parent
                width: parent.width - 2 * Theme.spacingL
                icon: "🖥"
                title: qsTr("La administración se hace desde el computador")
                message: qsTr("Use el cliente de escritorio o el panel web del servidor. Esta app es para estudiantes y profesores.")
            }
            AppButton {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: Theme.spacingXl
                text: qsTr("Cerrar sesión")
                variant: "secondary"
                onClicked: sessionManager.clear()
            }
        }
    }

    Connections {
        target: sessionManager
        function onSessionChanged() {
            if (!sessionManager.isAuthenticated) {
                stackView.replace(null, loginComponent)
            } else if (!sessionManager.debeCambiarContrasena && stackView.currentItem
                       && stackView.currentItem.obligatorio === true) {
                stackView.replace(null, window.inicio())
            }
        }
    }
}
