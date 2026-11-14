#ifndef SINCRONIZACION_H
#define SINCRONIZACION_H

#include <QDateTime>
#include <QJsonArray>
#include <QObject>
#include <QTimer>
#include <QUrl>
#include <QVariant>

class QNetworkReply;

namespace Rep {

/**
 * Estado de conexión con el servidor y cola de envíos pendientes
 * (propiedad de contexto "sincronizacion").
 *
 * - `enLinea` se actualiza con cada respuesta de red de la aplicación.
 * - Las operaciones que no pueden perderse (p. ej. entregar una actividad) se encolan
 *   si no hay conexión y se reenvían automáticamente al recuperarla.
 */
class Sincronizacion : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enLinea READ enLinea NOTIFY estadoChanged)
    Q_PROPERTY(int pendientes READ pendientes NOTIFY estadoChanged)
    Q_PROPERTY(QString ultimaConexion READ ultimaConexion NOTIFY estadoChanged)

public:
    static Sincronizacion &instance();

    bool enLinea() const { return m_enLinea; }
    int pendientes() const { return m_cola.size(); }
    QString ultimaConexion() const;

    /** Registra el resultado de una respuesta de red (lo llama HttpClient). */
    void registrar(QNetworkReply *reply);

    /** Guarda una petición para enviarla cuando vuelva la conexión. */
    void encolar(const QByteArray &metodo, const QUrl &url, const QByteArray &cuerpo, const QString &descripcion);

    Q_INVOKABLE void reintentarAhora();

    /**
     * El servidor cambió de dirección (mismo servidor, otra IP): los envíos pendientes
     * que apuntaban a la dirección anterior pasan a la nueva.
     */
    void reubicar(const QString &baseAnterior, const QString &baseNueva);

    /** Error de red sin respuesta del servidor (sin conexión, servidor apagado, tiempo agotado). */
    static bool esSinConexion(const QNetworkReply *reply);

signals:
    void estadoChanged();
    void envioCompletado(const QString &descripcion, const QVariant &respuesta);
    void envioRechazado(const QString &descripcion, const QString &mensaje);

private:
    Sincronizacion();
    void cargarCola();
    void guardarCola();
    void enviarSiguiente();
    QString archivoCola() const;

    bool m_enLinea = true;
    bool m_enviando = false;
    QDateTime m_ultimaConexion;
    QJsonArray m_cola;
    long long m_usuarioCola = -1;
    QTimer m_temporizador;
};

} // namespace Rep

#endif // SINCRONIZACION_H
