import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Rep
import "../components"

/*
 * Periodos académicos (administrador). Con periodos definidos, los reportes permiten
 * ver cada periodo y la nota anual se pondera por su porcentaje (Decreto 1290).
 */
Page {
    id: root
    property var periodos: []
    property int anio: new Date().getFullYear()

    background: Rectangle { color: Theme.background }
    header: PageHeader {
        title: qsTr("Periodos académicos")
        subtitle: qsTr("Año %1 · suma de porcentajes %2 %").arg(root.anio).arg(root.suma)
        AppButton {
            text: qsTr("+ Nuevo periodo")
            enabled: sincronizacion.enLinea && root.suma < 100
            onClicked: formulario.abrir(null)
        }
    }

    ApiRequests { id: requests }
    Toast { id: toast }

    readonly property int suma: periodos.reduce((t, p) => t + p.porcentaje, 0)

    function cargar() {
        requests.get("/admin/periodos?anio=" + anio, datos => { periodos = datos || [] },
                     m => toast.mostrar(m, "error"))
    }

    function fecha(iso) { return Qt.formatDate(new Date(iso + "T12:00:00"), "dd/MM/yyyy") }

    Component.onCompleted: cargar()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingM

        RowLayout {
            spacing: Theme.spacingS
            AppButton { text: "‹"; variant: "secondary"; onClicked: { root.anio--; root.cargar() } }
            Label { text: qsTr("Año lectivo %1").arg(root.anio); font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; color: Theme.textPrimary }
            AppButton { text: "›"; variant: "secondary"; onClicked: { root.anio++; root.cargar() } }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.textSecondary
            text: qsTr("Cada actividad pertenece al periodo que contiene su fecha de entrega. La nota anual es el promedio de los periodos ponderado por su porcentaje; los periodos aún sin notas no cuentan. Sin periodos, el promedio es la media de todas las actividades.")
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.periodos.length > 0 && root.suma !== 100
            implicitHeight: aviso.implicitHeight + 2 * Theme.spacingS
            radius: Theme.radiusM
            color: Theme.warningSoft
            Label {
                id: aviso
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                wrapMode: Text.WordWrap
                color: Theme.textPrimary
                text: qsTr("Los porcentajes suman %1 %. Complete el 100 % para que la nota anual refleje todo el año.").arg(root.suma)
            }
        }

        EmptyState {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.periodos.length === 0 && requests.enCurso === 0
            title: qsTr("Sin periodos para %1").arg(root.anio)
            message: qsTr("Cree, por ejemplo, cuatro periodos de 25 %.")
        }

        ListView {
            id: lista
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: count > 0
            clip: true
            spacing: Theme.spacingS
            model: root.periodos
            delegate: Card {
                id: tarjeta
                required property var modelData
                width: ListView.view.width
                padding: Theme.spacingM
                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingM
                    Avatar { text: String(tarjeta.modelData.numero); size: 36; Layout.preferredWidth: 36 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: tarjeta.modelData.nombre; font.weight: Font.DemiBold; color: Theme.textPrimary; Layout.fillWidth: true }
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("%1 a %2").arg(root.fecha(tarjeta.modelData.fechaInicio)).arg(root.fecha(tarjeta.modelData.fechaFin))
                            color: Theme.textSecondary; font.pixelSize: Theme.fontCaption
                        }
                    }
                    Label { Layout.preferredWidth: 80; horizontalAlignment: Text.AlignRight; text: tarjeta.modelData.porcentaje + " %"; font.pixelSize: Theme.fontTitle; font.weight: Font.Bold; color: Theme.primary }
                    AppButton { text: qsTr("Editar"); variant: "secondary"; enabled: sincronizacion.enLinea; onClicked: formulario.abrir(tarjeta.modelData) }
                    AppButton { text: qsTr("Eliminar"); variant: "danger"; enabled: sincronizacion.enLinea; onClicked: borrar.abrir(tarjeta.modelData) }
                }
            }
        }
    }

    Dialog {
        id: formulario
        property var periodo: null
        property string errorTexto: ""
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 480)
        title: periodo ? qsTr("Editar periodo") : qsTr("Nuevo periodo")
        standardButtons: Dialog.Save | Dialog.Cancel

        function abrir(p) {
            periodo = p
            errorTexto = ""
            const siguiente = root.periodos.length + 1
            numeroField.text = p ? String(p.numero) : String(siguiente)
            nombreField.text = p ? p.nombre : qsTr("Periodo %1").arg(siguiente)
            inicioField.text = p ? p.fechaInicio : ""
            finField.text = p ? p.fechaFin : ""
            porcentajeField.text = p ? String(p.porcentaje) : String(Math.max(0, 100 - root.suma))
            open()
        }

        onAccepted: {
            const iso = /^\d{4}-\d{2}-\d{2}$/
            if (!iso.test(inicioField.text.trim()) || !iso.test(finField.text.trim())) {
                errorTexto = qsTr("Las fechas deben tener el formato AAAA-MM-DD"); open(); return
            }
            const cuerpo = {
                anio: root.anio, numero: parseInt(numeroField.text), nombre: nombreField.text.trim(),
                fechaInicio: inicioField.text.trim(), fechaFin: finField.text.trim(),
                porcentaje: parseInt(porcentajeField.text)
            }
            const listo = () => { toast.mostrar(qsTr("Periodo guardado"), "exito"); root.cargar() }
            const fallo = m => { errorTexto = m; open() }
            if (periodo) requests.put("/admin/periodos/" + periodo.id, cuerpo, listo, fallo)
            else requests.post("/admin/periodos", cuerpo, listo, fallo)
        }

        GridLayout {
            anchors.fill: parent
            columns: 2
            columnSpacing: Theme.spacingM
            rowSpacing: Theme.spacingXs
            AppTextField { id: numeroField; label: qsTr("Número"); Layout.fillWidth: true; field.validator: IntValidator { bottom: 1; top: 12 } }
            AppTextField { id: porcentajeField; label: qsTr("Porcentaje (%)"); Layout.fillWidth: true; field.validator: IntValidator { bottom: 1; top: 100 } }
            AppTextField { id: nombreField; label: qsTr("Nombre"); Layout.fillWidth: true; Layout.columnSpan: 2 }
            AppTextField { id: inicioField; label: qsTr("Inicio (AAAA-MM-DD)"); Layout.fillWidth: true }
            AppTextField { id: finField; label: qsTr("Fin (AAAA-MM-DD)"); Layout.fillWidth: true }
            Label { visible: formulario.errorTexto !== ""; text: formulario.errorTexto; color: Theme.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.columnSpan: 2 }
        }
    }

    Dialog {
        id: borrar
        property var periodo: null
        function abrir(p) { periodo = p; open() }
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 420)
        title: qsTr("Eliminar periodo")
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: requests.eliminar("/admin/periodos/" + periodo.id, () => {
            toast.mostrar(qsTr("Periodo eliminado"), "exito"); root.cargar()
        }, m => toast.mostrar(m, "error"))
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.textPrimary
            text: borrar.periodo ? qsTr("¿Eliminar «%1»? Las actividades y notas no se borran; solo dejan de agruparse en ese periodo.").arg(borrar.periodo.nombre) : ""
        }
    }
}
