import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Material de estudio: guías, PDF, imágenes… se abren con las apps del teléfono. */
Page {
    id: root
    property bool conCabecera: false
    property var materiales: []
    property string busqueda: ""
    property string error: ""

    background: Rectangle { color: Theme.background }
    header: root.conCabecera ? cabecera : null
    PageHeader { id: cabecera; visible: root.conCabecera; title: qsTr("Material de estudio") }

    ApiRequests { id: requests }
    function cargar() { requests.get("/materiales", d => { materiales = d || []; error = "" }, m => { error = m }) }
    function visibles() {
        const q = busqueda.trim().toLowerCase()
        return q === "" ? materiales : materiales.filter(m => (m.titulo + " " + m.materiaNombre + " " + (m.descripcion || "")).toLowerCase().indexOf(q) >= 0)
    }
    function icono(tipo) {
        tipo = String(tipo || "")
        return tipo.startsWith("image/") ? "🖼" : tipo.indexOf("pdf") >= 0 ? "📕" : tipo.startsWith("video/") ? "🎬"
             : tipo.startsWith("audio/") ? "🎧" : "📄"
    }
    Component.onCompleted: cargar()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        RowLayout {
            Layout.fillWidth: true
            AppTextField { Layout.fillWidth: true; placeholderText: qsTr("Buscar…"); onTextChanged: root.busqueda = text }
            ToolButton { text: "↻"; font.pixelSize: 20; onClicked: root.cargar() }
        }
        Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }

        ListView {
            id: lista
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingS
            model: root.visibles()
            delegate: Card {
                id: tarjeta
                required property var modelData
                width: ListView.view.width
                padding: Theme.spacingM
                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM
                    Label { text: root.icono(tarjeta.modelData.tipoContenido); font.pixelSize: 26 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: tarjeta.modelData.titulo; font.weight: Font.DemiBold; color: Theme.textPrimary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        Label {
                            text: tarjeta.modelData.materiaNombre + " · " + api.tamanoLegible(tarjeta.modelData.tamanoBytes || 0)
                            color: Theme.textMuted; font.pixelSize: Theme.fontCaption; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                    AppButton { text: qsTr("Abrir"); variant: "secondary"; onClicked: api.abrir(tarjeta.modelData.archivoUrl) }
                }
            }
            Label {
                anchors.centerIn: parent
                visible: lista.count === 0 && requests.enCurso === 0 && root.error === ""
                color: Theme.textMuted
                text: qsTr("No hay material publicado")
            }
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.textMuted
            font.pixelSize: Theme.fontCaption
            text: qsTr("Lo que abre queda guardado en el teléfono y se puede ver sin conexión.")
        }
    }
}
