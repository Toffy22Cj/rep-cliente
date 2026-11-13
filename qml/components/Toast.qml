import QtQuick
import QtQuick.Controls
import Rep

// Notificación breve no bloqueante (abajo a la derecha).
Popup {
    id: toast
    property string mensaje: ""
    property string tipo: "info"   // info | exito | error

    function mostrar(texto, clase) {
        mensaje = texto
        tipo = clase || "info"
        open()
        cierre.restart()
    }

    x: parent ? parent.width - width - Theme.spacingL : 0
    y: parent ? parent.height - height - Theme.spacingL : 0
    width: Math.min(420, parent ? parent.width - 2 * Theme.spacingL : 420)
    padding: Theme.spacingM
    closePolicy: Popup.CloseOnPressOutside
    modal: false

    background: Rectangle {
        radius: Theme.radiusM
        color: toast.tipo === "error" ? Theme.dangerSoft : toast.tipo === "exito" ? Theme.successSoft : Theme.surface
        border.color: toast.tipo === "error" ? Theme.danger : toast.tipo === "exito" ? Theme.success : Theme.border
    }
    contentItem: Label {
        text: toast.mensaje
        wrapMode: Text.WordWrap
        color: toast.tipo === "error" ? Theme.dangerDark : toast.tipo === "exito" ? Theme.successDark : Theme.textPrimary
    }

    Timer { id: cierre; interval: toast.tipo === "error" ? 8000 : 4500; onTriggered: toast.close() }
}
