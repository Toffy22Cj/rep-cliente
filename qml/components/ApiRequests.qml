import QtQuick

/*
 * Envoltorio de la propiedad de contexto `api` con callbacks:
 *
 *   ApiRequests { id: requests }
 *   requests.get("/materiales", datos => ..., (mensaje, codigo) => ...)
 *
 * Solo atiende las respuestas de las peticiones que hizo esta instancia.
 */
QtObject {
    id: root
    property var _pendientes: ({})
    property int enCurso: 0

    function _registrar(id, ok, error) {
        _pendientes[id] = { ok: ok, error: error }
        enCurso++
        return id
    }

    function get(ruta, ok, error) { return _registrar(api.get(ruta), ok, error) }
    function post(ruta, cuerpo, ok, error) { return _registrar(api.post(ruta, cuerpo), ok, error) }
    function put(ruta, cuerpo, ok, error) { return _registrar(api.put(ruta, cuerpo), ok, error) }
    function eliminar(ruta, ok, error) { return _registrar(api.eliminar(ruta), ok, error) }
    function subir(ruta, archivo, campos, ok, error) { return _registrar(api.subir(ruta, archivo, campos || {}), ok, error) }

    property Connections _conexion: Connections {
        target: api
        function onRespuesta(id, datos) {
            const p = root._pendientes[id]
            if (!p) return
            delete root._pendientes[id]
            root.enCurso--
            if (p.ok) p.ok(datos)
        }
        function onFallo(id, mensaje, codigo) {
            const p = root._pendientes[id]
            if (!p) return
            delete root._pendientes[id]
            root.enCurso--
            if (p.error) p.error(mensaje, codigo)
        }
    }
}
