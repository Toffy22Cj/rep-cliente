#include "HttpClient.h"
#include "ApiConfig.h"
#include "../core/SessionManager.h"
#include "../core/AlmacenLocal.h"
#include "../core/Sincronizacion.h"

#include <QCoreApplication>

#include <QJsonDocument>
#include <QJsonObject>

Q_LOGGING_CATEGORY(lcApi, "rep.api", QtInfoMsg)

namespace Rep::HttpClient {

QNetworkAccessManager *red()
{
    static QNetworkAccessManager *nam = []() {
        auto *m = new QNetworkAccessManager(QCoreApplication::instance());
        QObject::connect(m, &QNetworkAccessManager::finished, m, [](QNetworkReply *reply) {
            Sincronizacion::instance().registrar(reply);
        });
        return m;
    }();
    return nam;
}

static QString claveDe(const QNetworkReply *reply)
{
    const QUrl url = reply->request().url();
    return url.path() + (url.hasQuery() ? QLatin1Char('?') + url.query() : QString());
}

bool leerConRespaldo(QNetworkReply *reply, QByteArray &cuerpo)
{
    if (reply->error() == QNetworkReply::NoError) {
        cuerpo = reply->readAll();
        AlmacenLocal::guardar(claveDe(reply), cuerpo);
        return true;
    }
    if (Sincronizacion::esSinConexion(reply)) {
        if (auto copia = AlmacenLocal::leer(claveDe(reply))) {
            cuerpo = *copia;
            return true;
        }
    }
    return false;
}

QNetworkRequest jsonRequest(const QUrl &url, const QString &token)
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Accept", "application/json");
    request.setTransferTimeout(30000);
    if (!token.isEmpty())
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    return request;
}

QNetworkRequest jsonRequest(const QString &apiPath, const QString &token)
{
    return jsonRequest(QUrl(ApiConfig::url(apiPath)), token);
}

int httpStatus(const QNetworkReply *reply)
{
    return reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
}

static QString messageFromBody(const QByteArray &body)
{
    const QJsonDocument doc = QJsonDocument::fromJson(body);
    if (doc.isObject()) {
        const QJsonObject obj = doc.object();
        for (const char *key : {"message", "mensaje", "error"}) {
            const QString value = obj.value(QLatin1String(key)).toString();
            if (!value.isEmpty())
                return value;
        }
    }
    // Algunos endpoints devuelven texto plano
    const QString text = QString::fromUtf8(body).trimmed();
    return text.size() <= 200 ? text : QString();
}

QString errorMessage(QNetworkReply *reply)
{
    const int status = httpStatus(reply);
    const bool authenticated = reply->request().hasRawHeader("Authorization");

    if (status == 401 && authenticated) {
        SessionManager::instance().clear();
        return QStringLiteral("Su sesión ha expirado. Inicie sesión nuevamente.");
    }

    const QString serverMessage = messageFromBody(reply->readAll());
    if (!serverMessage.isEmpty())
        return serverMessage;

    switch (status) {
    case 0:   return QStringLiteral("Sin conexión con el servidor (%1). Los datos guardados no incluyen esta información todavía.").arg(ApiConfig::baseUrl());
    case 400: return QStringLiteral("La solicitud contiene datos no válidos.");
    case 401: return QStringLiteral("Credenciales inválidas.");
    case 403: return QStringLiteral("No tiene permisos para realizar esta acción.");
    case 404: return QStringLiteral("El recurso solicitado no existe.");
    case 409: return QStringLiteral("La operación entra en conflicto con datos existentes.");
    case 429: return QStringLiteral("Demasiadas solicitudes. Intente de nuevo en unos minutos.");
    default:
        if (status >= 500)
            return QStringLiteral("Error interno del servidor. Intente más tarde.");
        return reply->errorString();
    }
}

} // namespace Rep::HttpClient
