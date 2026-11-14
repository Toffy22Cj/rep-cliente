#include "AuthService.h"
#include "HttpClient.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>

namespace Rep {

AuthService::AuthService(QObject *parent)
    : QObject(parent), m_networkManager(HttpClient::red())
{
}

void AuthService::login(const QString &identificacion, const QString &password)
{
    QNetworkRequest request = HttpClient::jsonRequest(QStringLiteral("/auth/login"), QString());

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

    // 401 = credenciales inválidas (el cuerpo trae LoginResponse con el mensaje).
    // Cualquier otro error (sin conexión, 403 cuenta inactiva, 429 demasiados intentos,
    // 5xx) se traduce a un mensaje legible.
    const int status = HttpClient::httpStatus(reply);
    if (reply->error() != QNetworkReply::NoError && status != 401) {
        emit errorOccurred(HttpClient::errorMessage(reply));
        return;
    }

    const QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
    // Nota: no se registra la respuesta completa porque contiene el token JWT.

    LoginResponse response;
    response.success = obj["success"].toBool();
    response.mensaje = obj["mensaje"].toString();
    if (!response.success && response.mensaje.isEmpty())
        response.mensaje = QStringLiteral("Credenciales inválidas.");
    response.token = obj["token"].toString();

    if (obj.contains("usuario") && !obj["usuario"].isNull()) {
        QJsonObject userObj = obj["usuario"].toObject();
        response.usuario.id = userObj["id"].toVariant().toLongLong();
        response.usuario.nombre = userObj["nombre"].toString();
        response.usuario.apellido = userObj["apellido"].toString();
        response.usuario.correo = userObj["correo"].toString();
        response.usuario.identificacion = userObj["identificacion"].toString();
        response.usuario.debeCambiarContrasena = userObj["debeCambiarContrasena"].toBool();
        
        QString rolStr = userObj["rol"].toString().trimmed().toUpper();
        if (rolStr == "ADMIN") response.usuario.rol = Rol::ADMIN;
        else if (rolStr == "PROFESOR") response.usuario.rol = Rol::PROFESOR;
        else response.usuario.rol = Rol::ESTUDIANTE;
    }

    emit loginFinished(response);
}

} // namespace Rep
