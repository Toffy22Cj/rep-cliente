import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

Page {
    id: root
    background: Rectangle { color: Theme.background }

    property int selectedMateria: -1

    header: PageHeader {
        title: qsTr("Mi espacio")
        subtitle: qsTr("Materias y actividades pendientes")
        showBack: false

        AppButton {
            text: qsTr("📊 Mis notas")
            variant: "secondary"
            onClicked: root.StackView.view.push("MisNotasPage.qml")
        }
        AppButton {
            text: qsTr("📚 Material de estudio")
            variant: "secondary"
            onClicked: root.StackView.view.push("MaterialPage.qml")
        }
        AppButton {
            text: qsTr("↻ Actualizar")
            variant: "secondary"
            onClicked: root.reload()
        }
    }

    function reload() {
        selectedMateria = -1
        estudianteViewModel.loadMaterias()
        estudianteViewModel.loadActividades()
    }

    ColumnLayout {
        width: Math.min(parent.width - 2 * Theme.spacingXl, Theme.maxContentWidth)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.spacingL
        anchors.bottomMargin: Theme.spacingL
        spacing: Theme.spacingM

        Label {
            text: qsTr("Hola, %1 👋").arg(sessionManager.userName)
            color: Theme.textPrimary
            font.pixelSize: Theme.fontHeadline
            font.weight: Font.Bold
        }

        // ---- Materias (filtro) ----
        Label {
            text: qsTr("Mis materias")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontCaption
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            AppButton {
                text: qsTr("Todas")
                variant: root.selectedMateria === -1 ? "primary" : "secondary"
                onClicked: {
                    root.selectedMateria = -1
                    estudianteViewModel.loadActividades()
                }
            }

            Repeater {
                model: estudianteViewModel.materiaModel
                delegate: AppButton {
                    required property var model
                    text: model.nombre
                    variant: root.selectedMateria === model.id ? "primary" : "secondary"
                    onClicked: {
                        root.selectedMateria = model.id
                        estudianteViewModel.loadActividadesByMateria(model.id)
                    }
                }
            }
        }

        // ---- Actividades ----
        Label {
            text: qsTr("Actividades")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontCaption
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            Layout.topMargin: Theme.spacingS
        }

        ListView {
            id: actividadesList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: estudianteViewModel.actividadModel
            spacing: Theme.spacingS
            clip: true
            ScrollBar.vertical: ScrollBar {}

            EmptyState {
                anchors.centerIn: parent
                visible: actividadesList.count === 0 && !estudianteViewModel.isLoading
                icon: "🎉"
                title: qsTr("No hay actividades")
                message: qsTr("Cuando tus profesores publiquen actividades aparecerán aquí.")
            }

            delegate: Card {
                id: actCard
                required property var model
                readonly property bool entregada: model.estadoEntrega === "ENTREGADA"
                readonly property bool enCola: model.estadoEntrega === "EN_COLA"
                width: ListView.view.width
                hoverable: true
                padding: Theme.spacingM

                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM

                    Rectangle {
                        Layout.preferredWidth: 4
                        Layout.fillHeight: true
                        radius: 2
                        color: actCard.entregada ? Theme.success : actCard.model.estadoEntrega === "VENCIDA" ? Theme.danger : Theme.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXs
                        RowLayout {
                            spacing: Theme.spacingS
                            Label {
                                text: actCard.model.titulo
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSubtitle
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Badge { text: String(actCard.model.tipo).toUpperCase() }
                        }
                        Label {
                            text: actCard.model.materiaNombre
                            color: Theme.textSecondary
                        }
                        Label {
                            visible: actCard.model.fechaEntrega !== ""
                            text: qsTr("Entrega: %1").arg(actCard.model.fechaEntrega)
                            color: Theme.warning
                            font.pixelSize: Theme.fontCaption
                            font.weight: Font.Medium
                        }
                    }

                    // Ya entregada: "Hecho" con la nota y acceso al resultado
                    Badge {
                        visible: actCard.entregada
                        text: "✔ " + qsTr("Hecho") + (actCard.model.nota !== undefined && actCard.model.nota !== null
                                                        ? " · " + Number(actCard.model.nota).toFixed(1) : "")
                        tint: Theme.successDark; softTint: Theme.successSoft
                    }
                    Badge {
                        visible: actCard.enCola
                        text: qsTr("Enviada · se sincronizará")
                        tint: Theme.warning; softTint: Theme.warningSoft
                    }
                    Badge {
                        visible: actCard.model.estadoEntrega === "VENCIDA"
                        text: qsTr("Vencida")
                        tint: Theme.dangerDark; softTint: Theme.dangerSoft
                    }
                    AppButton {
                        visible: actCard.entregada
                        text: qsTr("Ver resultado")
                        variant: "secondary"
                        onClicked: resultado.abrir(actCard.model.id, actCard.model.titulo)
                    }
                    AppButton {
                        visible: !actCard.entregada && !actCard.enCola && actCard.model.estadoEntrega !== "VENCIDA"
                        text: actCard.model.estadoEntrega === "EN_CURSO" ? qsTr("Continuar") : qsTr("Resolver")
                        onClicked: estudianteViewModel.startActividad(actCard.model.id)
                    }
                }
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: estudianteViewModel.isLoading
        visible: running
    }

    ResultadoActividad { id: resultado }

    // Al sincronizarse una entrega hecha sin conexión, se recarga para mostrar la nota
    Connections {
        target: sincronizacion
        function onEnvioCompletado() { estudianteViewModel.loadActividades() }
    }

    Connections {
        target: estudianteViewModel
        function onActividadConPreguntasFetched() {
            root.StackView.view.push("ActivityResolutionPage.qml")
        }
        function onErrorOccurred(error) {
            errorDialog.text = error
            errorDialog.open()
        }
    }

    Dialog {
        id: errorDialog
        property alias text: errorLabel.text
        title: qsTr("No se pudo completar la acción")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok
        width: Math.min(root.width - 40, 420)
        Label {
            id: errorLabel
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }

    Component.onCompleted: reload()
}
