import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

/*
 * Elegir el servidor: los encontrados solos en la red (cable, Wi-Fi, red propia,
 * Bluetooth PAN) o una dirección escrita a mano.
 */
Dialog {
    id: root
    property string mensaje: ""
    property bool mensajeOk: true

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: Math.min(parent ? parent.width - 40 : 560, 560)
    title: qsTr("Servidor")
    standardButtons: Dialog.Close

    onOpened: { mensaje = ""; descubrimiento.buscar() }

    Connections {
        target: descubrimiento
        function onDireccionProbada(ok, texto) { root.mensaje = texto; root.mensajeOk = ok; if (ok) root.close() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingS

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.textSecondary
            text: qsTr("Servidores encontrados en la red de este equipo. Funciona con o sin internet.")
        }

        RowLayout {
            Layout.fillWidth: true
            BusyIndicator { running: descubrimiento.buscando; visible: running; implicitWidth: 28; implicitHeight: 28 }
            Label {
                Layout.fillWidth: true
                color: Theme.textSecondary
                text: descubrimiento.buscando ? qsTr("Buscando…")
                      : qsTr("%n servidor(es) encontrado(s)", "", descubrimiento.servidores.length)
            }
            AppButton { text: qsTr("↻ Buscar de nuevo"); variant: "secondary"; enabled: !descubrimiento.buscando; onClicked: descubrimiento.buscar() }
        }

        Repeater {
            model: descubrimiento.servidores
            delegate: Card {
                id: fila
                required property var modelData
                readonly property bool actual: modelData.id === descubrimiento.servidorId && modelData.url === descubrimiento.servidorUrl
                Layout.fillWidth: true
                padding: Theme.spacingS
                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM
                    Label { text: fila.modelData.local ? "💻" : "🖥"; font.pixelSize: Theme.fontTitle }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: fila.modelData.nombre; font.weight: Font.DemiBold; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: fila.modelData.ip + " · v" + fila.modelData.version; color: Theme.textMuted; font.pixelSize: Theme.fontCaption }
                    }
                    Badge { visible: fila.actual; text: qsTr("En uso"); tint: Theme.successDark; softTint: Theme.successSoft }
                    AppButton {
                        visible: !fila.actual
                        text: qsTr("Usar")
                        onClicked: { descubrimiento.seleccionar(fila.modelData); root.close() }
                    }
                }
            }
        }

        Label {
            visible: !descubrimiento.buscando && descubrimiento.servidores.length === 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.warning
            text: qsTr("No se encontró ningún servidor. Compruebe que este equipo está en la misma red que el servidor (mismo Wi-Fi, cable, red propia o Bluetooth PAN) o escriba su dirección. La dirección aparece en el panel web del servidor, sección Red.")
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border; Layout.topMargin: Theme.spacingS }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS
            AppTextField {
                id: direccion
                Layout.fillWidth: true
                label: qsTr("Escribir dirección")
                placeholderText: qsTr("p. ej. 192.168.1.10 o servidor:8080")
                onAccepted: descubrimiento.probarDireccion(text)
            }
            AppButton {
                Layout.alignment: Qt.AlignBottom
                text: qsTr("Conectar")
                enabled: direccion.text.trim() !== ""
                onClicked: descubrimiento.probarDireccion(direccion.text)
            }
        }
        Label {
            visible: root.mensaje !== ""
            text: root.mensaje
            color: root.mensajeOk ? Theme.successDark : Theme.danger
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
