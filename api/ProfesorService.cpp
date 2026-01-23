#include "ProfesorService.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

namespace Rep {

ProfesorService::ProfesorService(QObject *parent)
    : QObject(parent), m_networkManager(new QNetworkAccessManager(this))
{
}

QNetworkRequest ProfesorService::createRequest(const QUrl &url, const QString &token)
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    }
    return request;
}

void ProfesorService::fetchDashboardData(const QString &token)
{
    QUrl url("http://localhost:8080/api/profesor/dashboard");
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
        ProfesorDashboardDTO data;
        data.totalEstudiantes = obj["totalEstudiantes"].toInt();
        data.actividadesActivas = obj["actividadesActivas"].toInt();
        data.entregasPendientes = obj["entregasPendientes"].toInt();
        
        QJsonArray matArr = obj["materias"].toArray();
        for (const auto &mVal : matArr) {
            QJsonObject mObj = mVal.toObject();
            MateriaAsignadaDTO m;
            m.id = mObj["id"].toVariant().toLongLong();
            m.nombre = mObj["nombre"].toString();
            data.materias.append(m);
        }
        emit dashboardDataFetched(data);
    });
}

void ProfesorService::fetchMateriasAsignadas(const QString &token)
{
    QUrl url("http://localhost:8080/api/profesor/materias");
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<MateriaAsignadaDTO> materias;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &mVal : array) {
            QJsonObject obj = mVal.toObject();
            materias.append({obj["id"].toVariant().toLongLong(), obj["nombre"].toString()});
        }
        emit materiasAsignadasFetched(materias);
    });
}

void ProfesorService::fetchCursos(const QString &token)
{
    QUrl url("http://localhost:8080/api/profesor/cursos");
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<CursoDTO> cursos;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &cVal : array) {
            QJsonObject obj = cVal.toObject();
            cursos.append({obj["id"].toVariant().toLongLong(), obj["nombre"].toString(), obj["grado"].toInt()});
        }
        emit cursosFetched(cursos);
    });
}

void ProfesorService::fetchActividades(long long materiaId, long long cursoId, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/actividades?materiaId=%1\u0026cursoId=%2").arg(materiaId).arg(cursoId));
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<ActividadDTO> actividades;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &aVal : array) {
            QJsonObject obj = aVal.toObject();
            ActividadDTO act;
            act.id = obj["id"].toVariant().toLongLong();
            act.titulo = obj["titulo"].toString();
            act.tipo = obj["tipo"].toString();
            act.fechaEntrega = QDate::fromString(obj["fechaHoraEntrega"].toString(), Qt::ISODate);
            actividades.append(act);
        }
        emit actividadesFetched(actividades);
    });
}

void ProfesorService::fetchRespuestas(long long actividadId, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/profesor/actividades/%1/respuestas").arg(actividadId));
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<RespuestaEstudianteSimplificadaDTO> respuestas;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &rVal : array) {
            QJsonObject obj = rVal.toObject();
            respuestas.append({
                obj["id"].toVariant().toLongLong(),
                obj["estudianteId"].toVariant().toLongLong(),
                obj["nombreEstudiante"].toString(),
                (float)obj["nota"].toDouble(),
                QDateTime::fromString(obj["fechaEntrega"].toString(), Qt::ISODate),
                obj["calificada"].toBool()
            });
        }
        emit respuestasFetched(respuestas);
    });
}

void ProfesorService::calificarRespuesta(long long respuestaId, float nota, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/profesor/respuestas/%1/calificar?nota=%2").arg(respuestaId).arg(nota));
    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QByteArray());
    connect(reply, &QNetworkReply::finished, this, [this, reply, respuestaId, nota]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        emit respuestaCalificada(respuestaId, nota);
    });
}

void ProfesorService::fetchEstudiantes(long long cursoId, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/profesor/estudiantes/curso/%1").arg(cursoId));
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<EstudianteSimplificadoDTO> estudiantes;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &v : array) {
            QJsonObject obj = v.toObject();
            estudiantes.append({
                obj["id"].toVariant().toLongLong(),
                obj["nombre"].toString(),
                obj["identificacion"].toString(),
                obj["correo"].toString()
            });
        }
        emit estudiantesFetched(estudiantes);
    });
}

void ProfesorService::fetchAsistencia(long long cursoId, long long materiaId, const QDate &fecha, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/profesor/asistencia?cursoId=%1\u0026materiaId=%2\u0026fecha=%3")
        .arg(cursoId).arg(materiaId).arg(fecha.toString(Qt::ISODate)));
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<AsistenciaDTO> asistencias;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto &v : array) {
            QJsonObject obj = v.toObject();
            QJsonObject est = obj["estudiante"].toObject();
            asistencias.append({
                est["id"].toVariant().toLongLong(),
                est["nombre"].toString(),
                obj["asistio"].toBool(),
                obj["observaciones"].toString()
            });
        }
        emit asistenciaFetched(asistencias);
    });
}

void ProfesorService::saveAsistencia(long long cursoId, long long materiaId, const QDate &fecha, const QList<AsistenciaDTO> &asistencia, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/profesor/asistencia?cursoId=%1\u0026materiaId=%2\u0026fecha=%3")
        .arg(cursoId).arg(materiaId).arg(fecha.toString(Qt::ISODate)));
    
    QJsonArray array;
    for (const auto &a : asistencia) {
        QJsonObject obj;
        obj["estudianteId"] = a.estudianteId;
        obj["asistio"] = a.asistio;
        obj["observaciones"] = a.observaciones;
        array.append(obj);
    }

    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QJsonDocument(array).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            emit asistenciaSaved(false);
            return;
        }
        emit asistenciaSaved(true);
    });
}

void ProfesorService::crearActividad(const ActividadCreateDTO &actividat, const QString &token)
{
    QUrl url("http://localhost:8080/api/actividades");
    QJsonObject obj;
    obj["titulo"] = actividat.titulo;
    obj["tipo"] = actividat.tipo;
    obj["descripcion"] = actividat.descripcion;
    obj["fechaEntrega"] = actividat.fechaEntrega.toString(Qt::ISODate);
    obj["duracionMinutos"] = actividat.duracionMinutos;
    obj["materiaId"] = actividat.materiaId;
    obj["cursoId"] = actividat.cursoId;

    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        QJsonObject res = QJsonDocument::fromJson(reply->readAll()).object();
        emit actividadCreada(res["id"].toVariant().toLongLong());
    });
}

void ProfesorService::actualizarActividad(long long id, const ActividadCreateDTO &actividat, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/actividades/%1").arg(id));
    QJsonObject obj;
    obj["titulo"] = actividat.titulo;
    obj["tipo"] = actividat.tipo;
    obj["descripcion"] = actividat.descripcion;
    obj["fechaEntrega"] = actividat.fechaEntrega.toString(Qt::ISODate);
    obj["duracionMinutos"] = actividat.duracionMinutos;
    obj["materiaId"] = actividat.materiaId;
    obj["cursoId"] = actividat.cursoId;

    QNetworkReply *reply = m_networkManager->put(createRequest(url, token), QJsonDocument(obj).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            emit actividadActualizada(false);
            return;
        }
        emit actividadActualizada(true);
    });
}

void ProfesorService::crearPregunta(const PreguntaRequestDTO &pregunta, const QString &token)
{
    QUrl url("http://localhost:8080/api/preguntas");
    QJsonObject root;
    root["actividadId"] = pregunta.actividadId;
    root["enunciado"] = pregunta.enunciado;
    root["tipo"] = pregunta.tipo;

    QJsonArray ops;
    for (const auto &o : pregunta.opciones) {
        QJsonObject oObj;
        oObj["texto"] = o.texto;
        oObj["esCorrecta"] = o.esCorrecta;
        ops.append(oObj);
    }
    root["opciones"] = ops;

    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QJsonDocument(root).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }
        QJsonObject res = QJsonDocument::fromJson(reply->readAll()).object();
        emit preguntaCreada(res["id"].toVariant().toLongLong());
    });
}

} // namespace Rep

