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

} // namespace Rep
