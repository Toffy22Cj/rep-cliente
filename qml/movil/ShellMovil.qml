import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Estructura de la app móvil: cabecera con el menú del usuario y navegación inferior
 * por pestañas según el rol. Cada pestaña se crea al abrirla por primera vez.
 */
Page {
    id: root
    property string rol: "ESTUDIANTE"

    readonly property var pestanas: rol === "PROFESOR" ? [
        { titulo: qsTr("Hoy"), icono: "🏠", archivo: "HoyProfesorMovil.qml" },
        { titulo: qsTr("Asistencia"), icono: "✅", archivo: "AsistenciaMovil.qml" },
        { titulo: qsTr("Calificar"), icono: "📝", archivo: "CalificarMovil.qml" },
        { titulo: qsTr("Horario"), icono: "🕘", archivo: "HorarioMovil.qml" }
    ] : [
        { titulo: qsTr("Actividades"), icono: "📋", archivo: "ActividadesMovil.qml" },
        { titulo: qsTr("Notas"), icono: "📊", archivo: "NotasMovil.qml" },
        { titulo: qsTr("Horario"), icono: "🕘", archivo: "HorarioMovil.qml" },
        { titulo: qsTr("Material"), icono: "📚", archivo: "MaterialMovil.qml" }
    ]

    /** Abre una pestaña desde otra (p. ej. «Tomar asistencia» desde el horario). */
    function irA(archivo, propiedades) {
        const i = pestanas.findIndex(p => p.archivo === archivo)
        if (i < 0) return
        barra.currentIndex = i
        const cargador = repetidor.itemAt(i)
        cargador.visitado = true
        if (propiedades && cargador.item && cargador.item.abrirCon) cargador.item.abrirCon(propiedades)
    }

    background: Rectangle { color: Theme.background }

    header: ToolBar {
        implicitHeight: 56
        background: Rectangle {
            color: Theme.surface
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.border }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingS
            Label {
                Layout.fillWidth: true
                text: root.pestanas[barra.currentIndex].titulo
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
            ToolButton {
                Accessible.name: qsTr("Menú de usuario")
                onClicked: menu.open()
                contentItem: Avatar { text: sessionManager.userInitials; size: 34 }
                Menu {
                    id: menu
                    y: parent.height
                    MenuItem { text: sessionManager.userFullName; enabled: false }
                    MenuSeparator {}
                    MenuItem { text: qsTr("Mi perfil"); onTriggered: stackView.push(Qt.resolvedUrl("../pages/PerfilPage.qml")) }
                    MenuItem {
                        visible: root.rol === "PROFESOR"
                        height: visible ? implicitHeight : 0
                        text: qsTr("Material de estudio")
                        onTriggered: stackView.push(Qt.resolvedUrl("MaterialMovil.qml"), { conCabecera: true })
                    }
                    MenuItem { text: qsTr("Servidor"); onTriggered: selector.open() }
                    MenuSeparator {}
                    MenuItem { text: qsTr("Cerrar sesión"); onTriggered: sessionManager.clear() }
                }
            }
        }
    }

    SelectorServidor { id: selector }

    StackLayout {
        anchors.fill: parent
        currentIndex: barra.currentIndex
        Repeater {
            id: repetidor
            model: root.pestanas
            delegate: Loader {
                id: cargador
                required property var modelData
                required property int index
                property bool visitado: index === 0
                active: visitado
                source: modelData.archivo
                Connections {
                    target: barra
                    function onCurrentIndexChanged() { if (barra.currentIndex === cargador.index) cargador.visitado = true }
                }
                // Las pestañas del profesor piden abrir la asistencia de una clase
                Connections {
                    target: cargador.item
                    ignoreUnknownSignals: true
                    function onAbrirAsistencia(bloque) { root.irA("AsistenciaMovil.qml", bloque) }
                    function onIrAPestana(archivo) { root.irA(archivo) }
                }
            }
        }
    }

    footer: TabBar {
        id: barra
        implicitHeight: 64
        background: Rectangle {
            color: Theme.surface
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Theme.border }
        }
        Repeater {
            model: root.pestanas
            delegate: TabButton {
                id: boton
                required property var modelData
                required property int index
                height: barra.height
                contentItem: ColumnLayout {
                    spacing: 2
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: boton.modelData.icono
                        font.pixelSize: 20
                        opacity: boton.checked ? 1 : 0.55
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: boton.modelData.titulo
                        font.pixelSize: Theme.fontCaption
                        font.weight: boton.checked ? Font.DemiBold : Font.Normal
                        color: boton.checked ? Theme.primary : Theme.textSecondary
                    }
                }
                background: Rectangle { color: boton.checked ? Theme.primarySoft : "transparent" }
            }
        }
    }
}
