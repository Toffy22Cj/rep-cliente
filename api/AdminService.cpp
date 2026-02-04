#include "AdminService.h"
#include "ApiConfig.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

namespace Rep {

AdminService::AdminService(QObject *parent)
    : QObject(parent), m_networkManager(new QNetworkAccessManager(this))
{
}

QNetworkRequest AdminService::createRequest(const QUrl &url, const QString &token)
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    }
    return request;
}

// --- Usuarios ---

void AdminService::fetchUsuarios(const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + "/admin/usuarios");
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<UsuarioDTO> usuarios;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &val : array) {
            QJsonObject obj = val.toObject();
            UsuarioDTO u;
            u.id = obj["id"].toVariant().toLongLong();
            u.nombre = obj["nombre"].toString();
            u.correo = obj["correo"].toString();
            u.rol = obj["rol"].toString();
            u.activo = obj["activo"].toBool();
            usuarios.append(u);
        }
        emit usuariosFetched(usuarios);
    });
}

void AdminService::updateUsuario(const UsuarioDTO &usuario, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + QString("/admin/usuarios/%1").arg(usuario.id));
    QJsonObject obj;
    obj["nombre"] = usuario.nombre;
    obj["correo"] = usuario.correo;
    obj["rol"] = usuario.rol;
    obj["activo"] = usuario.activo;
    if (!usuario.password.isEmpty()) {
        obj["contraseña"] = usuario.password;
    }

    QNetworkReply *reply = m_networkManager->put(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Usuario actualizado correctamente");
    });
}

void AdminService::deleteUsuario(long long id, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + QString("/admin/usuarios/%1").arg(id));
    QNetworkReply *reply = m_networkManager->deleteResource(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Usuario eliminado");
    });
}

void AdminService::toggleUsuarioEstado(long long id, bool activo, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + QString("/admin/usuarios/%1/estado?activo=%2").arg(id).arg(activo));
    QNetworkReply *reply = m_networkManager->put(createRequest(url, token), QByteArray());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Estado de usuario actualizado");
    });
}

// --- Cursos ---

void AdminService::fetchCursos(const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + "/admin/cursos");
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<CursoAdminDTO> cursos;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &val : array) {
            QJsonObject obj = val.toObject();
            CursoAdminDTO c;
            c.id = obj["id"].toVariant().toLongLong();
            c.grado = obj["grado"].toInt();
            c.grupo = obj["grupo"].toString();
            cursos.append(c);
        }
        emit cursosFetched(cursos);
    });
}

void AdminService::createCurso(const CursoAdminDTO &curso, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + "/admin/cursos");
    QJsonObject obj;
    obj["grado"] = curso.grado;
    obj["grupo"] = curso.grupo;

    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Curso creado");
    });
}

void AdminService::updateCurso(const CursoAdminDTO &curso, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + QString("/admin/cursos/%1").arg(curso.id));
    QJsonObject obj;
    obj["grado"] = curso.grado;
    obj["grupo"] = curso.grupo;

    QNetworkReply *reply = m_networkManager->put(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Curso actualizado");
    });
}

void AdminService::deleteCurso(long long id, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + QString("/admin/cursos/%1").arg(id));
    QNetworkReply *reply = m_networkManager->deleteResource(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Curso eliminado");
    });
}

// --- Materias ---

void AdminService::fetchMaterias(const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + "/admin/materias");
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<MateriaAdminDTO> materias;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &val : array) {
            QJsonObject obj = val.toObject();
            MateriaAdminDTO m;
            m.id = obj["id"].toVariant().toLongLong();
            m.nombre = obj["nombre"].toString();
            materias.append(m);
        }
        emit materiasFetched(materias);
    });
}

void AdminService::createMateria(const MateriaAdminDTO &materia, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + "/admin/materias");
    QJsonObject obj;
    obj["nombre"] = materia.nombre;

    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Materia creada");
    });
}

void AdminService::updateMateria(const MateriaAdminDTO &materia, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + QString("/admin/materias/%1").arg(materia.id));
    QJsonObject obj;
    obj["nombre"] = materia.nombre;

    QNetworkReply *reply = m_networkManager->put(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Materia actualizada");
    });
}

void AdminService::deleteMateria(long long id, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + QString("/admin/materias/%1").arg(id));
    QNetworkReply *reply = m_networkManager->deleteResource(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Materia eliminada");
    });
}



// --- Asignaciones ---

void AdminService::fetchAsignaciones(const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + "/admin/asignaciones");
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QByteArray data = reply->readAll();
        qDebug() << "fetchAsignaciones JSON:" << data;

        QList<AsignacionDTO> asignaciones;
        QJsonArray array = QJsonDocument::fromJson(data).array();
        for (const auto &val : array) {
            QJsonObject obj = val.toObject();
            AsignacionDTO a;
            a.id = obj["id"].toVariant().toLongLong();
            
            // Profesor info
            if (obj["profesor"].isObject()) {
                QJsonObject prof = obj["profesor"].toObject();
                a.profesorId = prof["id"].toVariant().toLongLong();
                a.profesorNombre = prof["nombre"].toString();
            }

            // Materia info
            if (obj["materia"].isObject()) {
                QJsonObject mat = obj["materia"].toObject();
                a.materiaId = mat["id"].toVariant().toLongLong();
                a.materiaNombre = mat["nombre"].toString();
            }

            // Curso info
            if (obj["curso"].isObject()) {
                QJsonObject cur = obj["curso"].toObject();
                a.cursoId = cur["id"].toVariant().toLongLong();
                
                QString gradoStr = QString::number(cur["grado"].toInt());
                QString grupo = cur["grupo"].toString();
                a.cursoNombre = gradoStr + "° " + grupo;
            }

            asignaciones.append(a);
        }
        emit asignacionesFetched(asignaciones);
    });
}

void AdminService::createAsignacion(long long profesorId, long long materiaId, long long cursoId, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + "/admin/asignaciones");
    QJsonObject obj;
    QJsonObject prof; prof["id"] = profesorId;
    QJsonObject mat; mat["id"] = materiaId;
    QJsonObject cur; cur["id"] = cursoId;
    
    obj["profesor"] = prof;
    obj["materia"] = mat;
    obj["curso"] = cur;

    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Asignación creada correctamente");
        // Opt: Fetch again to update list, or rely on caller
    });
}

void AdminService::deleteAsignacion(long long id, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + QString("/admin/asignaciones/%1").arg(id));
    QNetworkReply *reply = m_networkManager->deleteResource(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Asignación eliminada");
    });
}

} // namespace Rep
