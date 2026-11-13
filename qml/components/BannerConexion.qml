import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

/*
 * Aviso global de conexión: sin conexión se siguen mostrando los últimos datos
 * guardados y las entregas quedan en cola hasta que vuelva la red.
 */
Rectangle {
    id: banner
    readonly property bool mostrar: sessionManager.isAuthenticated
                                    && (!sincronizacion.enLinea || sincronizacion.pendientes > 0)
    visible: mostrar
    implicitHeight: mostrar ? fila.implicitHeight + 2 * Theme.spacingS : 0
    color: sincronizacion.enLinea ? Theme.infoSoft : Theme.warningSoft
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animNormal } }

    RowLayout {
        id: fila
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingS

        Label {
            text: sincronizacion.enLinea ? "🔄" : "📴"
            font.pixelSize: 16
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.textPrimary
            text: {
                let t = sincronizacion.enLinea
                        ? qsTr("Conexión recuperada. Enviando datos pendientes…")
                        : qsTr("Sin conexión con el servidor: se muestran los últimos datos guardados")
                          + (sincronizacion.ultimaConexion !== "" ? qsTr(" (última conexión: %1)").arg(sincronizacion.ultimaConexion) : "")
                          + "."
                if (sincronizacion.pendientes > 0)
                    t += " " + qsTr("%n envío(s) pendiente(s).", "", sincronizacion.pendientes)
                return t
            }
        }
        AppButton {
            visible: !sincronizacion.enLinea || sincronizacion.pendientes > 0
            text: qsTr("Reintentar")
            variant: "secondary"
            implicitHeight: 30
            onClicked: sincronizacion.reintentarAhora()
        }
    }
}
