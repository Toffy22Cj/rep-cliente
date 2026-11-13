#include "ApiCliente.h"
#include "ApiConfig.h"
#include "HttpClient.h"
#include "../core/SessionManager.h"
#include "../core/AlmacenLocal.h"
#include "../core/Sincronizacion.h"

#include <QCryptographicHash>
#include <QDesktopServices>
#include <QJsonArray>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHttpMultiPart>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QMimeDatabase>
#include <QNetworkReply>
#include <QSaveFile>
#include <QStandardPaths>

namespace Rep {

ApiCliente::ApiCliente(QObject *parent)
    : QObject(parent), m_red(HttpClient::red())
{
}

QUrl ApiCliente::urlServidor(const QString &ruta)
{
    QString base = ApiConfig::baseUrl();
    if (ruta.startsWith(QLatin1String("/api/")) && base.endsWith(QLatin1String("/api")))
        base.chop(4);
    return QUrl(base + (ruta.startsWith('/') ? ruta : QLatin1Char('/') + ruta));
}

int ApiCliente::get(const QString &ruta) { return enviar("GET", ruta, {}); }
int ApiCliente::post(const QString &ruta, const QVariant &cuerpo) { return enviar("POST", ruta, cuerpo); }
int ApiCliente::put(const QString &ruta, const QVariant &cuerpo) { return enviar("PUT", ruta, cuerpo); }
int ApiCliente::eliminar(const QString &ruta) { return enviar("DELETE", ruta, {}); }

int ApiCliente::enviar(const QByteArray &metodo, const QString &ruta, const QVariant &cuerpo)
{
    const int id = m_siguienteId++;
    QNetworkRequest request = HttpClient::jsonRequest(urlServidor(ruta), SessionManager::instance().token());
    QByteArray datos;
    if (cuerpo.isValid() && !cuerpo.isNull())
        datos = QJsonDocument::fromVariant(cuerpo).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = m_red->sendCustomRequest(request, metodo, datos);
    const bool lectura = metodo == "GET";
    connect(reply, &QNetworkReply::finished, this, [this, id, reply, lectura]() {
        if (lectura) {
            // Lecturas: si no hay conexión se usa la última copia guardada
            QByteArray cuerpo;
            if (HttpClient::leerConRespaldo(reply, cuerpo)) {
                reply->deleteLater();
                emit respuesta(id, cuerpo.isEmpty() ? QVariant() : QJsonDocument::fromJson(cuerpo).toVariant());
                return;
            }
        }
        atender(id, reply);
    });
    return id;
}

void ApiCliente::atender(int id, QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        // HttpClient::errorMessage consume el cuerpo; se lee antes el código
        const QByteArray cuerpo = reply->peek(reply->bytesAvailable());
        const QString codigo = QJsonDocument::fromJson(cuerpo).object().value("code").toString();
        emit fallo(id, HttpClient::errorMessage(reply), codigo);
        return;
    }
    const QByteArray cuerpo = reply->readAll();
    emit respuesta(id, cuerpo.isEmpty() ? QVariant() : QJsonDocument::fromJson(cuerpo).toVariant());
}

int ApiCliente::subir(const QString &ruta, const QUrl &archivoLocal, const QVariantMap &campos)
{
    const int id = m_siguienteId++;
    const QString rutaLocal = archivoLocal.isLocalFile() ? archivoLocal.toLocalFile() : archivoLocal.toString();
    auto *archivo = new QFile(rutaLocal);
    if (!archivo->open(QIODevice::ReadOnly)) {
        delete archivo;
        QMetaObject::invokeMethod(this, [this, id, rutaLocal]() {
            emit fallo(id, tr("No se pudo leer el archivo %1").arg(rutaLocal), QStringLiteral("ARCHIVO_LOCAL"));
        }, Qt::QueuedConnection);
        return id;
    }

    auto *multipart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    for (auto it = campos.cbegin(); it != campos.cend(); ++it) {
        QHttpPart parte;
        parte.setHeader(QNetworkRequest::ContentDispositionHeader,
                        QStringLiteral("form-data; name=\"%1\"").arg(it.key()));
        parte.setBody(it.value().toString().toUtf8());
        multipart->append(parte);
    }
    const QString nombre = QFileInfo(rutaLocal).fileName();
    QHttpPart parteArchivo;
    parteArchivo.setHeader(QNetworkRequest::ContentTypeHeader, QMimeDatabase().mimeTypeForFile(rutaLocal).name());
    parteArchivo.setHeader(QNetworkRequest::ContentDispositionHeader,
                           QStringLiteral("form-data; name=\"file\"; filename=\"%1\"").arg(nombre));
    parteArchivo.setBodyDevice(archivo);
    archivo->setParent(multipart);
    multipart->append(parteArchivo);

    QNetworkRequest request(urlServidor(ruta));
    request.setRawHeader("Authorization", "Bearer " + SessionManager::instance().token().toUtf8());
    request.setRawHeader("Accept", "application/json");
    QNetworkReply *reply = m_red->post(request, multipart);
    multipart->setParent(reply);
    connect(reply, &QNetworkReply::finished, this, [this, id, reply]() { atender(id, reply); });
    return id;
}

/*
 * Caché persistente de archivos por usuario (<datos sin conexión>/archivos + índice
 * archivos.json con la ETag de cada uno). Con conexión se revalida con If-None-Match
 * (respuesta 304 sin cuerpo si no cambió); sin conexión se usa la copia local.
 */
static QString indiceArchivos() { return AlmacenLocal::directorioUsuario() + "/archivos.json"; }

static QJsonObject leerIndice()
{
    QFile f(indiceArchivos());
    return f.open(QIODevice::ReadOnly) ? QJsonDocument::fromJson(f.readAll()).object() : QJsonObject();
}

static void guardarIndice(const QJsonObject &indice)
{
    QSaveFile f(indiceArchivos());
    if (f.open(QIODevice::WriteOnly)) {
        f.write(QJsonDocument(indice).toJson(QJsonDocument::Compact));
        f.commit();
    }
}

void ApiCliente::entregarLocal(const QString &ruta, const QUrl &local)
{
    emit archivoListo(ruta, local);
    if (m_abrirAlDescargar.remove(ruta))
        QDesktopServices::openUrl(local);
}

void ApiCliente::descargar(const QString &ruta)
{
    const QJsonObject entrada = leerIndice().value(ruta).toObject();
    const QString local = entrada.value("archivo").toString();
    const bool enCache = !local.isEmpty() && QFile::exists(local);

    // Sin conexión: directamente la copia guardada
    if (enCache && !Sincronizacion::instance().enLinea()) {
        QMetaObject::invokeMethod(this, [this, ruta, local]() { entregarLocal(ruta, QUrl::fromLocalFile(local)); },
                                  Qt::QueuedConnection);
        return;
    }
    // Si ya se está descargando, el resultado llegará por la misma señal
    if (m_descargando.contains(ruta))
        return;
    m_descargando.insert(ruta);

    QNetworkRequest request(urlServidor(ruta));
    request.setRawHeader("Authorization", "Bearer " + SessionManager::instance().token().toUtf8());
    request.setTransferTimeout(60000);
    if (enCache && entrada.contains("etag"))
        request.setRawHeader("If-None-Match", entrada.value("etag").toString().toUtf8());
    QNetworkReply *reply = m_red->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, ruta, reply, enCache, local]() {
        reply->deleteLater();
        m_descargando.remove(ruta);
        const int estado = HttpClient::httpStatus(reply);
        if (enCache && (estado == 304 || Sincronizacion::esSinConexion(reply))) {
            entregarLocal(ruta, QUrl::fromLocalFile(local)); // no cambió, o sin conexión
            return;
        }
        if (reply->error() != QNetworkReply::NoError) {
            m_abrirAlDescargar.remove(ruta);
            emit archivoFallo(ruta, HttpClient::errorMessage(reply));
            return;
        }
        // Nombre del archivo desde Content-Disposition (filename*=UTF-8''...) o la ruta
        QString nombre = QFileInfo(ruta).fileName();
        const QString disposicion = QString::fromUtf8(reply->rawHeader("Content-Disposition"));
        const int utf8 = disposicion.indexOf(QLatin1String("filename*=UTF-8''"), 0, Qt::CaseInsensitive);
        if (utf8 >= 0)
            nombre = QUrl::fromPercentEncoding(disposicion.mid(utf8 + 17).section(';', 0, 0).toUtf8());
        else if (disposicion.contains(QLatin1String("filename=")))
            nombre = disposicion.section(QLatin1String("filename="), 1).section(';', 0, 0).remove('"');
        nombre.replace('/', '_').replace('\\', '_');

        const QString dir = AlmacenLocal::directorioUsuario() + "/archivos";
        QDir().mkpath(dir);
        const QString hash = QString::fromLatin1(
            QCryptographicHash::hash(ruta.toUtf8(), QCryptographicHash::Sha1).toHex().left(10));
        const QString destino = dir + '/' + hash + '_' + nombre;
        // Escritura atómica: nunca se deja un archivo a medias que otra vista esté leyendo
        QSaveFile archivo(destino);
        if (!archivo.open(QIODevice::WriteOnly) || archivo.write(reply->readAll()) < 0 || !archivo.commit()) {
            emit archivoFallo(ruta, tr("No se pudo guardar el archivo en %1").arg(destino));
            return;
        }
        QJsonObject indice = leerIndice();
        QJsonObject e;
        e["archivo"] = destino;
        e["etag"] = QString::fromUtf8(reply->rawHeader("ETag"));
        indice[ruta] = e;
        guardarIndice(indice);
        entregarLocal(ruta, QUrl::fromLocalFile(destino));
    });
}

void ApiCliente::abrir(const QString &ruta)
{
    m_abrirAlDescargar.insert(ruta);
    descargar(ruta);
}

QString ApiCliente::espacioSinConexion() const
{
    return tamanoLegible(AlmacenLocal::tamanoUsuario());
}

void ApiCliente::borrarDatosSinConexion()
{
    AlmacenLocal::borrarUsuario();
}

QString ApiCliente::tamanoLegible(qint64 bytes)
{
    return QLocale(QLocale::Spanish).formattedDataSize(bytes, 1, QLocale::DataSizeTraditionalFormat);
}

} // namespace Rep
