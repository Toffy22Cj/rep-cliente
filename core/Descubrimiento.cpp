#include "Descubrimiento.h"
#include "Sincronizacion.h"
#include "../api/ApiConfig.h"
#include "../api/HttpClient.h"

#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkInterface>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSettings>
#include <QUrl>

namespace Rep {

static const char *GRUPO_MULTICAST = "239.255.47.80";

Descubrimiento &Descubrimiento::instance()
{
    static Descubrimiento inst;
    return inst;
}

Descubrimiento::Descubrimiento()
{
    m_fin.setSingleShot(true);
    connect(&m_fin, &QTimer::timeout, this, &Descubrimiento::terminarBusqueda);
    // Se repite la búsqueda dentro de la ventana: un paquete UDP se puede perder
    m_reenvio.setInterval(700);
    connect(&m_reenvio, &QTimer::timeout, this, &Descubrimiento::enviarBusqueda);
    connect(&m_consulta, &QUdpSocket::readyRead, this, [this]() { leer(&m_consulta); });
    connect(&m_anuncios, &QUdpSocket::readyRead, this, [this]() { leer(&m_anuncios); });

    // Al perder la conexión, se busca el servidor (pudo cambiar de IP o de red)
    connect(&Sincronizacion::instance(), &Sincronizacion::estadoChanged, this, [this]() {
        if (!Sincronizacion::instance().enLinea() && !m_buscando)
            reconectar();
    });
}

quint16 Descubrimiento::puerto(const char *clave, quint16 porDefecto)
{
    const int p = QSettings().value(QString::fromLatin1(clave), porDefecto).toInt();
    return p > 0 && p < 65536 ? quint16(p) : porDefecto;
}

QString Descubrimiento::servidorUrl() const
{
    QString base = ApiConfig::baseUrl();
    if (base.endsWith(QLatin1String("/api")))
        base.chop(4);
    return base;
}

QString Descubrimiento::servidorNombre() const
{
    return QSettings().value("api/servidorNombre").toString();
}

QString Descubrimiento::servidorId() const
{
    return QSettings().value("api/servidorId").toString();
}

bool Descubrimiento::configurado() const
{
    return !qEnvironmentVariableIsEmpty("REP_API_URL") || QSettings().contains("api/baseUrl");
}

void Descubrimiento::iniciar()
{
    // Escucha pasiva de anuncios; varios clientes en el mismo equipo comparten el puerto
    if (m_anuncios.state() != QAbstractSocket::BoundState) {
        if (!m_anuncios.bind(QHostAddress::AnyIPv4, puerto("red/puertoAnuncio", 47801),
                             QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
            qWarning("Descubrimiento: no se pudo escuchar anuncios (%s)", qPrintable(m_anuncios.errorString()));
        } else {
            m_anuncios.joinMulticastGroup(QHostAddress(QString::fromLatin1(GRUPO_MULTICAST)));
        }
    }
    if (!configurado()) {
        m_elegirSiHayUno = true;
        buscar();
    }
}

void Descubrimiento::buscar(int milisegundos)
{
    if (m_consulta.state() != QAbstractSocket::BoundState)
        m_consulta.bind(QHostAddress::AnyIPv4, 0);
    if (!m_buscando) {
        m_buscando = true;
        // Lista nueva: los servidores apagados desaparecen (los anuncios la vuelven a llenar)
        m_servidores.clear();
        emit servidoresChanged();
        emit buscandoChanged();
    }
    enviarBusqueda();
    m_reenvio.start();
    m_fin.start(qMax(500, milisegundos));
}

void Descubrimiento::enviarBusqueda()
{
    const QByteArray mensaje = R"({"rep":"buscar","v":1})";
    const quint16 destino = puerto("red/puertoDescubrimiento", 47800);
    QList<QHostAddress> direcciones{QHostAddress::Broadcast, QHostAddress::LocalHost,
                                    QHostAddress(QString::fromLatin1(GRUPO_MULTICAST))};
    // Broadcast de cada red conectada: LAN, Wi-Fi, red propia y Bluetooth PAN a la vez
    for (const QNetworkInterface &ni : QNetworkInterface::allInterfaces()) {
        const auto f = ni.flags();
        if (!(f & QNetworkInterface::IsUp) || !(f & QNetworkInterface::IsRunning) || (f & QNetworkInterface::IsLoopBack))
            continue;
        for (const QNetworkAddressEntry &e : ni.addressEntries()) {
            if (e.ip().protocol() == QAbstractSocket::IPv4Protocol && !e.broadcast().isNull())
                direcciones.append(e.broadcast());
        }
    }
    for (const QHostAddress &d : std::as_const(direcciones))
        m_consulta.writeDatagram(mensaje, d, destino);
}

void Descubrimiento::leer(QUdpSocket *socket)
{
    while (socket->hasPendingDatagrams()) {
        QByteArray datos;
        datos.resize(int(socket->pendingDatagramSize()));
        QHostAddress origen;
        socket->readDatagram(datos.data(), datos.size(), &origen);
        const QJsonObject obj = QJsonDocument::fromJson(datos).object();
        if (obj.value("rep").toString() == QLatin1String("servidor") && !obj.value("id").toString().isEmpty())
            registrar(obj, origen);
    }
}

void Descubrimiento::registrar(const QJsonObject &obj, const QHostAddress &origen)
{
    // La IP desde la que llegó el mensaje es la que este equipo sabe alcanzar
    QHostAddress ip = origen;
    bool convertida = false;
    const quint32 v4 = ip.toIPv4Address(&convertida);
    if (convertida)
        ip = QHostAddress(v4);
    const bool local = ip.isLoopback();
    const int puertoHttp = obj.value("puerto").toInt(8080);
    const QString url = QStringLiteral("http://%1:%2").arg(local ? QStringLiteral("localhost") : ip.toString()).arg(puertoHttp);
    const QString id = obj.value("id").toString();

    QVariantMap servidor{{"id", id}, {"nombre", obj.value("nombre").toString()},
                         {"version", obj.value("version").toString()}, {"url", url},
                         {"ip", local ? QStringLiteral("este equipo") : ip.toString()}, {"local", local},
                         {"visto", QDateTime::currentMSecsSinceEpoch()}};

    bool cambio = true;
    int existente = -1;
    for (int i = 0; i < m_servidores.size(); ++i) {
        if (m_servidores.at(i).toMap().value("id").toString() == id) { existente = i; break; }
    }
    if (existente >= 0) {
        const QVariantMap anterior = m_servidores.at(existente).toMap();
        // En el propio equipo servidor se prefiere localhost: no depende de la IP de la red
        if (anterior.value("local").toBool() && !local) {
            cambio = false;
        } else {
            cambio = anterior.value("url") != url || anterior.value("nombre") != servidor.value("nombre");
            m_servidores[existente] = servidor;
        }
    } else {
        m_servidores.append(servidor);
    }
    if (cambio)
        emit servidoresChanged();

    // Es el servidor guardado pero en otra dirección, y la actual no responde: cambiar solo
    if (id == servidorId() && url != servidorUrl()
        && (m_buscarParaReconectar || !Sincronizacion::instance().enLinea())) {
        const QString anterior = servidorUrl();
        usar(id, servidor.value("nombre").toString(), url);
        Sincronizacion::instance().reubicar(anterior + "/api", url + "/api");
        m_buscarParaReconectar = false;
        emit reconectado(servidor.value("nombre").toString(), url);
        Sincronizacion::instance().reintentarAhora();
    }
}

void Descubrimiento::terminarBusqueda()
{
    m_reenvio.stop();
    m_buscando = false;
    m_buscarParaReconectar = false;
    emit buscandoChanged();
    if (m_elegirSiHayUno && m_servidores.size() == 1 && !configurado())
        seleccionar(m_servidores.first().toMap());
    m_elegirSiHayUno = false;
    emit busquedaTerminada(int(m_servidores.size()));
}

void Descubrimiento::seleccionar(const QVariantMap &servidor)
{
    usar(servidor.value("id").toString(), servidor.value("nombre").toString(), servidor.value("url").toString());
}

void Descubrimiento::usar(const QString &id, const QString &nombre, const QString &url)
{
    if (url.isEmpty())
        return;
    QSettings s;
    s.setValue("api/baseUrl", url + "/api");
    s.setValue("api/servidorId", id);
    s.setValue("api/servidorNombre", nombre);
    emit servidorChanged();
}

void Descubrimiento::reconectar()
{
    if (servidorId().isEmpty())
        return;
    m_buscarParaReconectar = true;
    buscar();
}

QString Descubrimiento::normalizarDireccion(const QString &texto)
{
    QString t = texto.trimmed();
    if (t.isEmpty())
        return {};
    if (!t.contains(QLatin1String("://")))
        t.prepend(QLatin1String("http://"));
    QUrl url(t, QUrl::StrictMode);
    if (!url.isValid() || url.host().isEmpty() || (url.scheme() != QLatin1String("http") && url.scheme() != QLatin1String("https")))
        return {};
    if (url.port() == -1 && url.scheme() == QLatin1String("http"))
        url.setPort(8080);
    url.setPath(QString());
    url.setQuery(QString());
    url.setFragment(QString());
    QString r = url.toString();
    while (r.endsWith('/'))
        r.chop(1);
    return r;
}

void Descubrimiento::probarDireccion(const QString &texto)
{
    const QString base = normalizarDireccion(texto);
    if (base.isEmpty()) {
        emit direccionProbada(false, tr("Escriba una dirección como 192.168.1.10 o servidor:8080"));
        return;
    }
    QNetworkRequest req(QUrl(base + "/api/public/servidor"));
    req.setTransferTimeout(5000);
    QNetworkReply *reply = HttpClient::red()->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, base]() {
        reply->deleteLater();
        const QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
        if (reply->error() != QNetworkReply::NoError || obj.value("rep").toString() != QLatin1String("servidor")) {
            emit direccionProbada(false, tr("No hay un servidor REP en %1").arg(base));
            return;
        }
        const QString anterior = servidorUrl();
        const bool mismo = obj.value("id").toString() == servidorId();
        usar(obj.value("id").toString(), obj.value("nombre").toString(), base);
        if (mismo)
            Sincronizacion::instance().reubicar(anterior + "/api", base + "/api");
        emit direccionProbada(true, tr("Conectado a %1").arg(obj.value("nombre").toString()));
    });
}

} // namespace Rep
