import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep

/*
 * Muestra un archivo adjunto de la API: las imágenes se descargan (con el token de la
 * sesión) y se ven en línea; el resto de archivos se abren con la aplicación del sistema.
 */
ColumnLayout {
    id: root
    property string url: ""          // p. ej. "/api/preguntas/5/archivo"
    property string nombre: ""
    property bool esImagen: false
    property int alturaMaxima: 320

    property url _local: ""
    property string _error: ""
    visible: url !== ""
    spacing: Theme.spacingXs

    onUrlChanged: cargar()
    Component.onCompleted: cargar()

    function cargar() {
        _local = ""
        _error = ""
        if (url !== "" && esImagen)
            api.descargar(url)
    }

    Connections {
        target: api
        function onArchivoListo(ruta, urlLocal) { if (ruta === root.url) root._local = urlLocal }
        function onArchivoFallo(ruta, mensaje) { if (ruta === root.url) root._error = mensaje }
    }

    // ---- Imagen en línea ----
    Rectangle {
        visible: root.esImagen
        Layout.fillWidth: true
        Layout.maximumWidth: 560
        Layout.preferredHeight: imagen.status === Image.Ready
                                ? Math.min(root.alturaMaxima, imagen.paintedHeight + 2 * Theme.spacingS) : 120
        radius: Theme.radiusM
        color: Theme.surfaceAlt
        border.color: Theme.border

        Image {
            id: imagen
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            source: root._local
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }
        BusyIndicator {
            anchors.centerIn: parent
            running: root._local == "" && root._error === ""
            visible: running
        }
        Label {
            anchors.centerIn: parent
            visible: root._error !== ""
            text: root._error
            color: Theme.danger
            wrapMode: Text.WordWrap
            width: parent.width - 2 * Theme.spacingM
            horizontalAlignment: Text.AlignHCenter
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: api.abrir(root.url)
            ToolTip.visible: containsMouse
            ToolTip.text: qsTr("Abrir en tamaño completo")
            hoverEnabled: true
        }
    }

    // ---- Otros archivos ----
    RowLayout {
        visible: !root.esImagen
        spacing: Theme.spacingS
        Label { text: "📎"; font.pixelSize: 18 }
        Label {
            text: root.nombre !== "" ? root.nombre : qsTr("Archivo adjunto")
            color: Theme.textPrimary
            elide: Text.ElideMiddle
            Layout.maximumWidth: 360
        }
        AppButton {
            text: qsTr("Abrir")
            variant: "secondary"
            implicitHeight: 32
            onClicked: api.abrir(root.url)
        }
    }
}
