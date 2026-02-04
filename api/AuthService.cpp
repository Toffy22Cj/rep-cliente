#include "AuthService.h"
#include "ApiConfig.h"
#include "../utils/ValidationUtils.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>

namespace Rep
{

    AuthService::AuthService(QObject *parent)
        : BaseService(parent)
    {
    }

    void AuthService::login(const QString &identificacion, const QString &password)
    {
        qDebug() << "AuthService: login llamado para" << identificacion;
        if (!ValidationUtils::isValidIdentification(identificacion))
        {
            emit errorOccurred("Identificación inválida (3-20 caracteres alfanuméricos)");
            return;
        }

        if (!ValidationUtils::isValidPassword(password))
        {
            emit errorOccurred("Contraseña inválida (mínimo 6 caracteres)");
            return;
        }

        QUrl url(ApiConfig::baseUrl() + "/auth/login");
        qDebug() << "AuthService: Enviando petición POST a" << url.toString();

        QNetworkRequest request = createRequest(url, ""); // Use BaseService helper

        QJsonObject json;
        json["identificacion"] = identificacion;
        json["password"] = password;

        QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(json).toJson());
        connect(reply, &QNetworkReply::finished, this, [this, reply]()
                { onLoginReply(reply); });
    }

    void AuthService::onLoginReply(QNetworkReply *reply)
    {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError && reply->error() != QNetworkReply::AuthenticationRequiredError)
        {
            qCritical() << "AuthService: Error de red:" << reply->errorString();
            emit errorOccurred(reply->errorString());
            return;
        }

        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject obj = doc.object();
        // Removed sensitive log: qDebug() << "Login JSON Response:" << data;
        qDebug() << "AuthService: Login response received (success:" << obj["success"].toBool() << ")";
        qDebug() << "AuthService: Response token empty:" << obj["token"].toString().isEmpty();
        qDebug() << "AuthService: Response has usuario:" << obj.contains("usuario");

        LoginResponse response;
        response.success = obj["success"].toBool();
        response.mensaje = obj["mensaje"].toString();
        response.token = obj["token"].toString();

        if (obj.contains("usuario") && !obj["usuario"].isNull())
        {
            QJsonObject userObj = obj["usuario"].toObject();
            response.usuario.id = userObj["id"].toVariant().toLongLong();
            response.usuario.nombre = userObj["nombre"].toString();
            response.usuario.correo = userObj["correo"].toString();
            response.usuario.identificacion = userObj["identificacion"].toString();

            QString rolStr = userObj["rol"].toString().trimmed().toUpper();
            qDebug() << "Rol recibido del backend:" << rolStr;

            if (rolStr == "ADMIN")
                response.usuario.rol = Rol::ADMIN;
            else if (rolStr == "PROFESOR")
                response.usuario.rol = Rol::PROFESOR;
            else
            {
                qDebug() << "Rol no reconocido o es ESTUDIANTE, asignando ESTUDIANTE.";
                response.usuario.rol = Rol::ESTUDIANTE;
            }
        }

        qDebug() << "AuthService: EMITIENDO loginFinished. Success:" << response.success;
        emit loginFinished(response);
        qDebug() << "AuthService: loginFinished emitido";
    }
} // namespace Rep
