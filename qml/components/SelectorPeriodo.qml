import QtQuick
import QtQuick.Controls
import Rep

/*
 * Selector "Año completo / Periodo N". Se oculta si la institución no definió periodos.
 *   SelectorPeriodo { onCambiado: cargar() }   // periodoId: null = año completo
 */
ComboBox {
    id: root
    property var periodoId: null
    property var periodos: []
    signal cambiado()

    visible: periodos.length > 0
    implicitWidth: 220
    textRole: "texto"
    model: [{ id: null, texto: qsTr("Año completo (ponderado)") }].concat(
               periodos.map(p => ({ id: p.id, texto: p.nombre + " · " + p.porcentaje + " %" })))

    onActivated: index => { periodoId = model[index].id; cambiado() }

    ApiRequests { id: requests }
    Component.onCompleted: requests.get("/periodos", datos => {
        periodos = datos || []
        // Por defecto, el periodo en curso
        const hoy = Qt.formatDate(new Date(), "yyyy-MM-dd")
        const i = periodos.findIndex(p => p.fechaInicio <= hoy && hoy <= p.fechaFin)
        if (i >= 0) { currentIndex = i + 1; periodoId = periodos[i].id; cambiado() }
    })

    /** Parámetro para la URL: "" (año completo) o separador + "periodoId=N". */
    function parametro(separador) {
        return periodoId === null || periodoId === undefined ? "" : (separador || "&") + "periodoId=" + periodoId
    }
}
