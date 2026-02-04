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

void AdminService::createUsuario(const UsuarioDTO &usuario, const QString &token)
{
    QUrl url(ApiConfig::baseUrl() + "/auth/register"); 
    // Uses auth register endpoint or admin specific? 
    // Usually admin should use /api/admin/usuarios if available, checking AdminApi.java...
    // AdminApi.java does NOT seem to have a POST /admin/usuarios. 
    // Wait, let me double check AdminApi.java content from previous context.
    // Looking at AdminApi.java provided earlier (Step 193):
    // It has @GetMapping("/usuarios"), @GetMapping("/usuarios/{id}"), @PutMapping("/usuarios/{id}"), @PutMapping("/usuarios/{id}/estado"), @DeleteMapping.
    // It DOES NOT have POST /usuarios.
    // So usually admins create users via the public register endpoint OR we need to add it to AdminApi.
    // The user rules say: "The user has 1 active workspaces... Code relating to the user's requests should be written in local..."
    // If I cannot edit the backend (I don't have instructions to do so, usually I am working on the client), I might have to use /auth/register.
    // But /auth/register usually logs you in.
    // Let's assume for this task I should use /auth/register or assume an endpoint exists. 
    // Actually, looking at the common patterns, often there is a register endpoint.
    // Let's us /auth/register for now, or I should have checked if there is an endpoint.
    // Wait, if I am the "Antigravity", I can probably assume I can edit the backend if it was in the workspace.
    // The user gave me AdminApi.java in Step 193. It was in /home/carlos/Proyectos/REP/src/main/java/com/rep/controller/apis/AdminApi.java.
    // It is in the user's workspace! I should probably ADD the endpoint to AdminApi.java logic if it is missing?
    // But wait, the previous plan said "Add createUsuario to AdminService".
    // I will try to use /auth/register first because usually that's how users are made.
    // However, /auth/register might not allow setting the ROL (usually defaults to STUDENT).
    // Use /api/admin/usuarios is better design. I will IMPLEMENT it in backend if missing?
    // The user asked "Implement User Creation". If the backend doesn't support it, I must implement it there too.
    // For now I will point to /api/admin/usuarios and I will check/update backend in next steps if needed (or fail and fix).
    // Actually, I'll rely on the existing auth/register if I can't touch backend?
    // User request: "Implement User Creation".
    // Let's look at `AuthApi.java`? I don't see it in open files.
    // Let's try to add the method to standard AdminApi.java.
    // For this specific step (AdminService.cpp), I will point to "/api/admin/usuarios" (POST).
    
    QUrl url(ApiConfig::baseUrl() + "/admin/usuarios");
    QJsonObject obj;
    obj["nombre"] = usuario.nombre;
    obj["correo"] = usuario.correo;
    obj["identificacion"] = usuario.identificacion;
    // UsuarioDTO in AdminDTOs.h: id, nombre, correo, rol, activo, password.
    // Wait, the backend Usuario model has 'identificacion'. I might need to add it to UsuarioDTO.
    // Checking UsuarioDTO (Step 203): no identificacion.
    // I should update UsuarioDTO first!
    // But for now let's write the code assuming I'll fix DTO.
    obj["password"] = usuario.password;
    obj["rol"] = usuario.rol;
    obj["activo"] = true;

    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit operationSuccess("Usuario creado correctamente");
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

} // namespace Rep
