#include "AuthService.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>

namespace Rep {

AuthService::AuthService(QObject *parent)
    : QObject(parent), m_networkManager(new QNetworkAccessManager(this))
{
}

void AuthService::login(const QString &identificacion, const QString &password)
{
    QUrl url("http://localhost:8080/api/auth/login"); // Adjusted to common local port
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["identificacion"] = identificacion;
    json["password"] = password;

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(json).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onLoginReply(reply);
    });
}

void AuthService::onLoginReply(QNetworkReply *reply)
{
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError && reply->error() != QNetworkReply::AuthenticationRequiredError) {
        emit errorOccurred(reply->errorString());
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonObject obj = doc.object();

    LoginResponse response;
    response.success = obj["success"].toBool();
    response.mensaje = obj["mensaje"].toString();
    response.token = obj["token"].toString();

    if (obj.contains("usuario") && !obj["usuario"].isNull()) {
        QJsonObject userObj = obj["usuario"].toObject();
        response.usuario.id = userObj["id"].toVariant().toLongLong();
        response.usuario.nombre = userObj["nombre"].toString();
        response.usuario.correo = userObj["correo"].toString();
        response.usuario.identificacion = userObj["identificacion"].toString();
        
        QString rolStr = userObj["rol"].toString();
        if (rolStr == "ADMIN") response.usuario.rol = Rol::ADMIN;
        else if (rolStr == "PROFESOR") response.usuario.rol = Rol::PROFESOR;
        else response.usuario.rol = Rol::ESTUDIANTE;
    }

    emit loginFinished(response);
}

} // namespace Rep
