#include "Sincronizacion.h"
#include "SessionManager.h"
#include "../api/HttpClient.h"

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QSaveFile>
#include <QStandardPaths>

namespace Rep {

Sincronizacion &Sincronizacion::instance()
{
    static Sincronizacion inst;
    return inst;
}

Sincronizacion::Sincronizacion()
{
    m_temporizador.setInterval(30000);
    connect(&m_temporizador, &QTimer::timeout, this, &Sincronizacion::reintentarAhora);
    // La cola es por usuario: se carga al iniciar o cambiar la sesión
    connect(&SessionManager::instance(), &SessionManager::sessionChanged, this, [this]() {
        cargarCola();
        reintentarAhora();
    });
    cargarCola();
}

QString Sincronizacion::ultimaConexion() const
{
    return m_ultimaConexion.isValid() ? m_ultimaConexion.toString(QStringLiteral("dd/MM HH:mm")) : QString();
}

bool Sincronizacion::esSinConexion(const QNetworkReply *reply)
{
    if (reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() != 0)
        return false; // el servidor respondió (aunque sea con error)
    switch (reply->error()) {
    case QNetworkReply::ConnectionRefusedError:
    case QNetworkReply::RemoteHostClosedError:
    case QNetworkReply::HostNotFoundError:
    case QNetworkReply::TimeoutError:
    case QNetworkReply::OperationCanceledError:
    case QNetworkReply::TemporaryNetworkFailureError:
    case QNetworkReply::NetworkSessionFailedError:
    case QNetworkReply::UnknownNetworkError:
    case QNetworkReply::ProxyConnectionRefusedError:
    case QNetworkReply::ProxyTimeoutError:
        return true;
    default:
        return false;
    }
}

void Sincronizacion::registrar(QNetworkReply *reply)
{
    const bool conexion = !esSinConexion(reply);
    if (conexion)
        m_ultimaConexion = QDateTime::currentDateTime();
    if (conexion != m_enLinea) {
        m_enLinea = conexion;
        emit estadoChanged();
        if (m_enLinea)
            QTimer::singleShot(0, this, &Sincronizacion::reintentarAhora);
    }
}

QString Sincronizacion::archivoCola() const
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/sin-conexion";
    QDir().mkpath(dir);
    return dir + "/pendientes-" + QString::number(SessionManager::instance().userId()) + ".json";
}

void Sincronizacion::cargarCola()
{
    m_usuarioCola = SessionManager::instance().userId();
    m_cola = {};
    QFile f(archivoCola());
    if (m_usuarioCola > 0 && f.open(QIODevice::ReadOnly))
        m_cola = QJsonDocument::fromJson(f.readAll()).array();
    if (m_cola.isEmpty()) m_temporizador.stop(); else m_temporizador.start();
    emit estadoChanged();
}

void Sincronizacion::guardarCola()
{
    QSaveFile f(archivoCola());
    if (f.open(QIODevice::WriteOnly)) {
        f.write(QJsonDocument(m_cola).toJson(QJsonDocument::Compact));
        f.commit();
    }
    if (m_cola.isEmpty()) m_temporizador.stop(); else m_temporizador.start();
    emit estadoChanged();
}

void Sincronizacion::encolar(const QByteArray &metodo, const QUrl &url, const QByteArray &cuerpo,
                             const QString &descripcion)
{
    QJsonObject e;
    e["metodo"] = QString::fromLatin1(metodo);
    e["url"] = url.toString();
    e["cuerpo"] = QString::fromUtf8(cuerpo);
    e["descripcion"] = descripcion;
    e["creado"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    m_cola.append(e);
    guardarCola();
}

void Sincronizacion::reintentarAhora()
{
    if (!m_enviando && !m_cola.isEmpty() && SessionManager::instance().isAuthenticated()
        && m_usuarioCola == SessionManager::instance().userId())
        enviarSiguiente();
}

void Sincronizacion::enviarSiguiente()
{
    if (m_cola.isEmpty()) {
        m_enviando = false;
        return;
    }
    m_enviando = true;
    const QJsonObject e = m_cola.first().toObject();
    QNetworkRequest req = HttpClient::jsonRequest(QUrl(e["url"].toString()), SessionManager::instance().token());
    QNetworkReply *reply = HttpClient::red()->sendCustomRequest(req, e["metodo"].toString().toLatin1(),
                                                                e["cuerpo"].toString().toUtf8());
    connect(reply, &QNetworkReply::finished, this, [this, reply, e]() {
        reply->deleteLater();
        const QString descripcion = e["descripcion"].toString();
        if (reply->error() == QNetworkReply::NoError) {
            m_cola.removeFirst();
            guardarCola();
            emit envioCompletado(descripcion, QJsonDocument::fromJson(reply->readAll()).toVariant());
            enviarSiguiente();
        } else if (esSinConexion(reply)) {
            m_enviando = false; // se reintentará con el temporizador
        } else {
            // El servidor rechazó el envío (p. ej. plazo vencido): no se reintenta
            m_cola.removeFirst();
            guardarCola();
            emit envioRechazado(descripcion, HttpClient::errorMessage(reply));
            enviarSiguiente();
        }
    });
}

} // namespace Rep
