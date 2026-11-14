import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Planilla de notas del profesor: estudiantes × actividades de una materia y curso,
 * con promedios, desempeño, faltas y exportación a Excel/PDF. Pulsar el título de una
 * actividad abre su calificación.
 */
Page {
    id: root
    property var asignaciones: []
    property var planilla: null
    property string error: ""

    readonly property int anchoNombre: 230
    readonly property int anchoNota: 104
    readonly property int altoFila: 40

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: qsTr("Planilla de notas")
        subtitle: root.planilla ? qsTr("%1 · %2 · %3 · promedio del curso %4")
                                  .arg(root.planilla.materia).arg(root.planilla.curso)
                                  .arg(root.planilla.periodo ? root.planilla.periodo.nombre : root.planilla.ponderado ? qsTr("año ponderado") : qsTr("todas las actividades"))
                                  .arg(root.nota(root.planilla.promedioCurso)) : ""
        AppButton {
            text: qsTr("Excel")
            variant: "secondary"
            enabled: root.planilla !== null
            onClicked: root.exportar("xlsx")
        }
        AppButton {
            text: qsTr("PDF")
            variant: "secondary"
            enabled: root.planilla !== null
            onClicked: root.exportar("pdf")
        }
    }

    ApiRequests { id: requests }

    function nota(n) { return n === null || n === undefined ? "—" : Number(n).toFixed(1) }
    function colorNota(n) {
        if (n === null || n === undefined) return Theme.textMuted
        return n >= (planilla ? planilla.notaMinimaAprobatoria : 3.0) ? Theme.textPrimary : Theme.dangerDark
    }
    function textoCelda(c) {
        if (c.nota !== null && c.nota !== undefined) return nota(c.nota) + (c.estado === "ENTREGADA" ? "*" : "")
        return c.estado === "VENCIDA" ? qsTr("No entregó") : c.estado === "EN_CURSO" ? qsTr("En curso") : "—"
    }

    function asignacionActual() { return asignacionCombo.currentIndex >= 0 ? asignaciones[asignacionCombo.currentIndex] : null }

    function cargarPlanilla() {
        const a = asignacionActual()
        if (!a) return
        requests.get("/profesor/notas?cursoId=" + a.cursoId + "&materiaId=" + a.materiaId + selector.parametro(),
                     datos => { planilla = datos; error = "" },
                     mensaje => { error = mensaje })
    }

    function exportar(formato) {
        const a = asignacionActual()
        if (a) api.abrir("/api/profesor/notas/export?cursoId=" + a.cursoId + "&materiaId=" + a.materiaId + "&formato=" + formato + selector.parametro())
    }

    Component.onCompleted: requests.get("/profesor/asignaciones", datos => {
        asignaciones = datos || []
        if (asignaciones.length > 0) { asignacionCombo.currentIndex = 0; cargarPlanilla() }
    }, mensaje => { error = mensaje })

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM
            Label { text: qsTr("Materia y curso:"); color: Theme.textSecondary }
            ComboBox {
                id: asignacionCombo
                Layout.preferredWidth: 320
                model: root.asignaciones
                textRole: "nombre"
                onActivated: root.cargarPlanilla()
            }
            SelectorPeriodo { id: selector; onCambiado: root.cargarPlanilla() }
            Item { Layout.fillWidth: true }
            Badge {
                visible: root.planilla !== null
                text: qsTr("Aprobados: %1").arg(root.planilla ? root.planilla.aprobados : 0)
                tint: Theme.successDark; softTint: Theme.successSoft
            }
            Badge {
                visible: root.planilla !== null
                text: qsTr("En riesgo: %1").arg(root.planilla ? root.planilla.reprobados : 0)
                tint: Theme.dangerDark; softTint: Theme.dangerSoft
            }
        }

        Label { visible: root.error !== ""; text: root.error; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }

        EmptyState {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.asignaciones.length === 0 && requests.enCurso === 0
            title: qsTr("No tiene materias asignadas")
            message: qsTr("Pida al administrador que le asigne materias y cursos.")
        }

        // ------------------------------------------------ tabla
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.planilla !== null
            padding: 0

            Flickable {
                id: tabla
                anchors.fill: parent
                clip: true
                contentWidth: contenido.width
                contentHeight: contenido.height
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: contenido

                    // Cabecera
                    Row {
                        Rectangle {
                            width: root.anchoNombre; height: 56; color: Theme.surfaceAlt
                            Label { anchors.fill: parent; anchors.margins: Theme.spacingS; verticalAlignment: Text.AlignVCenter; text: qsTr("Estudiante"); font.weight: Font.DemiBold; color: Theme.textSecondary }
                        }
                        Repeater {
                            model: root.planilla ? root.planilla.actividades : []
                            delegate: Rectangle {
                                required property var modelData
                                width: root.anchoNota; height: 56; color: zonaCol.containsMouse ? Theme.primarySoft : Theme.surfaceAlt
                                Column {
                                    anchors.fill: parent; anchors.margins: 4; spacing: 0
                                    Label { width: parent.width; text: modelData.titulo; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold; color: Theme.textPrimary; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                                    Label { width: parent.width; text: modelData.tipo + " · " + modelData.entregas + " ent."; font.pixelSize: 10; color: Theme.textMuted; horizontalAlignment: Text.AlignHCenter }
                                    Label { width: parent.width; text: qsTr("prom. %1").arg(root.nota(modelData.promedio)); font.pixelSize: 10; color: Theme.textSecondary; horizontalAlignment: Text.AlignHCenter }
                                }
                                MouseArea {
                                    id: zonaCol
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    ToolTip.visible: containsMouse
                                    ToolTip.text: qsTr("Calificar «%1»").arg(modelData.titulo)
                                    onClicked: root.StackView.view.push("GradingPage.qml",
                                                                        { actividadId: modelData.actividadId, actividadTitulo: modelData.titulo })
                                }
                            }
                        }
                        Repeater {
                            model: root.planilla && root.planilla.ponderado ? root.planilla.periodos : []
                            delegate: Rectangle {
                                required property var modelData
                                width: root.anchoNota; height: 56; color: Theme.primarySoft
                                Column {
                                    anchors.centerIn: parent
                                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.nombre; font.pixelSize: Theme.fontCaption; font.weight: Font.DemiBold; color: Theme.textPrimary }
                                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.porcentaje + " %"; font.pixelSize: 10; color: Theme.textSecondary }
                                }
                            }
                        }
                        Repeater {
                            model: [root.planilla && root.planilla.ponderado ? qsTr("Final") : qsTr("Promedio"), qsTr("Desempeño"), qsTr("Faltas")]
                            delegate: Rectangle {
                                required property string modelData
                                width: root.anchoNota; height: 56; color: Theme.surfaceAlt
                                Label { anchors.centerIn: parent; text: modelData; font.weight: Font.DemiBold; color: Theme.textSecondary }
                            }
                        }
                    }

                    // Filas
                    Repeater {
                        model: root.planilla ? root.planilla.estudiantes : []
                        delegate: Row {
                            id: filaEst
                            required property var modelData
                            required property int index
                            readonly property color fondo: index % 2 === 0 ? Theme.surface : Theme.surfaceAlt
                            Rectangle {
                                width: root.anchoNombre; height: root.altoFila; color: filaEst.fondo
                                Label { anchors.fill: parent; anchors.leftMargin: Theme.spacingS; verticalAlignment: Text.AlignVCenter; text: filaEst.modelData.estudiante; elide: Text.ElideRight; color: Theme.textPrimary }
                            }
                            Repeater {
                                model: filaEst.modelData.notas
                                delegate: Rectangle {
                                    required property var modelData
                                    width: root.anchoNota; height: root.altoFila; color: filaEst.fondo
                                    Label {
                                        anchors.centerIn: parent
                                        text: root.textoCelda(modelData)
                                        color: modelData.estado === "VENCIDA" ? Theme.dangerDark : root.colorNota(modelData.nota)
                                        font.pixelSize: modelData.nota !== null ? Theme.fontBody : Theme.fontCaption
                                    }
                                }
                            }
                            Repeater {
                                model: root.planilla && root.planilla.ponderado ? filaEst.modelData.periodos : []
                                delegate: Rectangle {
                                    required property var modelData
                                    width: root.anchoNota; height: root.altoFila; color: filaEst.fondo
                                    Label { anchors.centerIn: parent; text: root.nota(modelData.promedio); color: root.colorNota(modelData.promedio) }
                                }
                            }
                            Rectangle {
                                width: root.anchoNota; height: root.altoFila; color: filaEst.fondo
                                Label { anchors.centerIn: parent; text: root.nota(filaEst.modelData.promedio); font.weight: Font.Bold; color: root.colorNota(filaEst.modelData.promedio) }
                            }
                            Rectangle {
                                width: root.anchoNota; height: root.altoFila; color: filaEst.fondo
                                Label {
                                    anchors.centerIn: parent
                                    text: { const d = filaEst.modelData.desempeno; return d === "SUPERIOR" ? qsTr("Superior") : d === "ALTO" ? qsTr("Alto") : d === "BASICO" ? qsTr("Básico") : d === "BAJO" ? qsTr("Bajo") : "—" }
                                    color: filaEst.modelData.desempeno === "BAJO" ? Theme.dangerDark : Theme.textSecondary
                                }
                            }
                            Rectangle {
                                width: root.anchoNota; height: root.altoFila; color: filaEst.fondo
                                Label { anchors.centerIn: parent; text: filaEst.modelData.ausencias; color: filaEst.modelData.ausencias > 2 ? Theme.warning : Theme.textSecondary }
                            }
                        }
                    }
                }
            }
        }

        Label {
            visible: root.planilla !== null
            text: qsTr("* Nota preliminar: la actividad tiene preguntas abiertas pendientes de revisión. “No entregó” cuenta como 0.0 en el promedio.")
            color: Theme.textMuted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
