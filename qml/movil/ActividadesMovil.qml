import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/* Estudiante: actividades por resolver y entregadas (con su nota). */
Item {
    id: root
    property string filtro: "pendientes"   // pendientes | hechas | todas

    function coincide(estado) {
        if (filtro === "todas") return true
        const hecha = estado === "ENTREGADA" || estado === "EN_COLA"
        return filtro === "hechas" ? hecha : !hecha && estado !== "VENCIDA"
    }
    function cargar() { estudianteViewModel.loadActividades() }

    Component.onCompleted: cargar()

    ResultadoActividad { id: resultado }

    Connections {
        target: estudianteViewModel
        function onActividadConPreguntasFetched() { stackView.push(Qt.resolvedUrl("../pages/ActivityResolutionPage.qml")) }
        function onActivitySubmitted(ok, mensaje) { if (ok) root.cargar() }
        function onErrorOccurred(error) { toastGlobal.mostrar(error, "error") }
    }
    Connections {
        target: sincronizacion
        function onEnvioCompletado() { root.cargar() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs
            Repeater {
                model: [{ v: "pendientes", t: qsTr("Pendientes") }, { v: "hechas", t: qsTr("Hechas") }, { v: "todas", t: qsTr("Todas") }]
                delegate: AppButton {
                    required property var modelData
                    text: modelData.t
                    variant: root.filtro === modelData.v ? "primary" : "secondary"
                    onClicked: root.filtro = modelData.v
                }
            }
            Item { Layout.fillWidth: true }
            ToolButton { text: "↻"; font.pixelSize: 20; Accessible.name: qsTr("Actualizar"); onClicked: root.cargar() }
        }

        ListView {
            id: lista
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingS
            model: estudianteViewModel.actividadModel

            BusyIndicator { anchors.centerIn: parent; running: estudianteViewModel.isLoading && lista.count === 0 }

            delegate: Item {
                id: fila
                required property var model
                readonly property bool mostrar: root.coincide(model.estadoEntrega)
                readonly property bool entregada: model.estadoEntrega === "ENTREGADA"
                width: ListView.view.width
                height: mostrar ? tarjeta.implicitHeight : 0
                visible: mostrar

                Card {
                    id: tarjeta
                    width: parent.width
                    padding: Theme.spacingM
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: fila.model.titulo
                                font.weight: Font.DemiBold
                                font.pixelSize: Theme.fontSubtitle
                                color: Theme.textPrimary
                                wrapMode: Text.WordWrap
                            }
                            Badge { text: String(fila.model.tipo).toUpperCase() }
                        }
                        Label {
                            text: fila.model.materiaNombre + (fila.model.fechaEntrega ? " · " + qsTr("entrega %1").arg(fila.model.fechaEntrega) : "")
                                  + (fila.model.duracion > 0 ? " · " + qsTr("%1 min").arg(fila.model.duracion) : "")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontCaption
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            Badge {
                                visible: fila.entregada
                                text: "✔ " + qsTr("Hecho") + (fila.model.nota !== undefined && fila.model.nota !== null ? " · " + Number(fila.model.nota).toFixed(1) : "")
                                tint: Theme.successDark; softTint: Theme.successSoft
                            }
                            Badge {
                                visible: fila.model.estadoEntrega === "EN_COLA"
                                text: qsTr("Enviada · se sincronizará")
                                tint: Theme.warning; softTint: Theme.warningSoft
                            }
                            Badge {
                                visible: fila.model.estadoEntrega === "VENCIDA"
                                text: qsTr("Vencida")
                                tint: Theme.dangerDark; softTint: Theme.dangerSoft
                            }
                            Item { Layout.fillWidth: true }
                            AppButton {
                                visible: fila.entregada
                                text: qsTr("Ver resultado")
                                variant: "secondary"
                                onClicked: resultado.abrir(fila.model.id, fila.model.titulo)
                            }
                            AppButton {
                                visible: !fila.entregada && fila.model.estadoEntrega !== "EN_COLA" && fila.model.estadoEntrega !== "VENCIDA"
                                text: fila.model.estadoEntrega === "EN_CURSO" ? qsTr("Continuar") : qsTr("Resolver")
                                enabled: !estudianteViewModel.isLoading
                                onClicked: estudianteViewModel.startActividad(fila.model.id)
                            }
                        }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                width: parent.width - 2 * Theme.spacingL
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: !estudianteViewModel.isLoading && lista.contentHeight < Theme.spacingS * lista.count + 10
                color: Theme.textMuted
                text: root.filtro === "pendientes" ? qsTr("🎉 No tiene actividades pendientes") : qsTr("No hay actividades")
            }
        }
    }
}
