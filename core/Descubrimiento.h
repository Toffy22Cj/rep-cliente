#ifndef DESCUBRIMIENTO_H
#define DESCUBRIMIENTO_H

#include <QObject>
#include <QTimer>
#include <QUdpSocket>
#include <QVariantList>
#include <QVariantMap>

namespace Rep {

/**
 * Encuentra servidores REP en cualquier red IP (cable, Wi-Fi, red propia del servidor,
 * Bluetooth PAN), con o sin internet (propiedad de contexto "descubrimiento").
 *
 * - Búsqueda activa: envía {"rep":"buscar"} por UDP a broadcast, multicast y localhost
 *   (puerto 47800) y recoge las respuestas.
 * - Escucha pasiva: recibe los anuncios periódicos del servidor (puerto 47801).
 * - Cada servidor se identifica por su `id`: si cambia de IP se reconoce y el cliente
 *   se reconecta solo (y mueve a la nueva dirección los envíos pendientes).
 * - Primera ejecución sin servidor configurado: si encuentra exactamente uno, lo usa.
 *
 * La dirección elegida se guarda en QSettings ("api/baseUrl", "api/servidorId").
 */
class Descubrimiento : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList servidores READ servidores NOTIFY servidoresChanged)
    Q_PROPERTY(bool buscando READ buscando NOTIFY buscandoChanged)
    Q_PROPERTY(QString servidorUrl READ servidorUrl NOTIFY servidorChanged)
    Q_PROPERTY(QString servidorNombre READ servidorNombre NOTIFY servidorChanged)
    Q_PROPERTY(QString servidorId READ servidorId NOTIFY servidorChanged)
    Q_PROPERTY(bool configurado READ configurado NOTIFY servidorChanged)

public:
    static Descubrimiento &instance();

    QVariantList servidores() const { return m_servidores; }
    bool buscando() const { return m_buscando; }
    QString servidorUrl() const;
    QString servidorNombre() const;
    QString servidorId() const;
    bool configurado() const;

    /** Abre la escucha de anuncios y, si no hay servidor configurado, busca uno. */
    void iniciar();

    Q_INVOKABLE void buscar(int milisegundos = 2500);
    /** Usa un servidor de la lista (mapa con id, nombre, url). */
    Q_INVOKABLE void seleccionar(const QVariantMap &servidor);
    /** Prueba una dirección escrita a mano ("192.168.1.10", "servidor:8080"…) y la usa si responde. */
    Q_INVOKABLE void probarDireccion(const QString &texto);
    /** Si el servidor guardado no responde, lo busca por su id en la red. */
    Q_INVOKABLE void reconectar();

    /** "192.168.1.10" → "http://192.168.1.10:8080" (sin /api). Vacío si no es válida. */
    static QString normalizarDireccion(const QString &texto);

signals:
    void servidoresChanged();
    void buscandoChanged();
    void servidorChanged();
    void busquedaTerminada(int encontrados);
    void direccionProbada(bool ok, const QString &mensaje);
    /** Se cambió solo a la nueva dirección del mismo servidor. */
    void reconectado(const QString &nombre, const QString &url);

private:
    Descubrimiento();
    void enviarBusqueda();
    void leer(QUdpSocket *socket);
    void registrar(const QJsonObject &obj, const QHostAddress &origen);
    void terminarBusqueda();
    void usar(const QString &id, const QString &nombre, const QString &url);
    static quint16 puerto(const char *clave, quint16 porDefecto);

    QUdpSocket m_consulta;
    QUdpSocket m_anuncios;
    QTimer m_fin;
    QTimer m_reenvio;
    QVariantList m_servidores;
    bool m_buscando = false;
    bool m_buscarParaReconectar = false;
    bool m_elegirSiHayUno = false;
};

} // namespace Rep

#endif // DESCUBRIMIENTO_H
