#include "EstudianteService.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QDebug>

namespace Rep {

EstudianteService::EstudianteService(QObject *parent)
    : QObject(parent), m_networkManager(new QNetworkAccessManager(this))
{
}

QNetworkRequest EstudianteService::createRequest(const QUrl &url, const QString &token)
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    }
    return request;
}

void EstudianteService::fetchMaterias(long long estudianteId, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/estudiante/%1/materias").arg(estudianteId));
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Fetch Materias Error:" << reply->errorString();
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<MateriaDTO> materias;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const QJsonValue &val : array) {
            QJsonObject obj = val.toObject();
            materias.append({obj["id"].toVariant().toLongLong(), obj["nombre"].toString()});
        }
        emit materiasFetched(materias);
    });
}

void EstudianteService::fetchActividades(long long estudianteId, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/estudiante/%1/actividades").arg(estudianteId));
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Fetch Actividades Error:" << reply->errorString();
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<ActividadDTO> actividades;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const QJsonValue &val : array) {
            QJsonObject obj = val.toObject();
            ActividadDTO act;
            act.id = obj["id"].toVariant().toLongLong();
            act.duracionMinutos = obj["duracionMinutos"].toInt();
            act.titulo = obj["titulo"].toString();
            act.tipo = obj["tipo"].toString();
            act.descripcion = obj["descripcion"].toString();
            act.fechaEntrega = QDate::fromString(obj["fechaEntrega"].toString(), Qt::ISODate);
            act.fechaCreacion = QDateTime::fromString(obj["fechaCreacion"].toString(), Qt::ISODate);
            act.materiaNombre = obj["materiaNombre"].toString();
            act.cursoNombre = obj["cursoNombre"].toString();
            actividades.append(act);
        }
        emit actividadesFetched(actividades);
    });
}

void EstudianteService::fetchActividadesByMateria(long long estudianteId, long long materiaId, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/estudiante/%1/materias/%2/actividades").arg(estudianteId).arg(materiaId));
    QNetworkReply *reply = m_networkManager->get(createRequest(url, token));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Fetch ActividadesByMateria Error:" << reply->errorString();
            emit errorOccurred(reply->errorString());
            return;
        }

        QList<ActividadDTO> actividades;
        QJsonArray array = QJsonDocument::fromJson(reply->readAll()).array();
        for (const QJsonValue &val : array) {
            QJsonObject obj = val.toObject();
            ActividadDTO act;
            act.id = obj["id"].toVariant().toLongLong();
            act.duracionMinutos = obj["duracionMinutos"].toInt();
            act.titulo = obj["titulo"].toString();
            act.tipo = obj["tipo"].toString();
            act.descripcion = obj["descripcion"].toString();
            act.fechaEntrega = QDate::fromString(obj["fechaEntrega"].toString(), Qt::ISODate);
            act.fechaCreacion = QDateTime::fromString(obj["fechaCreacion"].toString(), Qt::ISODate);
            act.materiaNombre = obj["materiaNombre"].toString();
            act.cursoNombre = obj["cursoNombre"].toString();
            actividades.append(act);
        }
        emit actividadesFetched(actividades);
    });
}

void EstudianteService::fetchActividadConPreguntas(long long actividadId, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/actividades/%1/preguntas").arg(actividadId));
    QNetworkRequest request = createRequest(url, token);
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, actividadId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Fetch Activity Questions Error [" << actividadId << "]:" << reply->errorString();
            emit errorOccurred(reply->errorString());
            return;
        }

        QByteArray data = reply->readAll();
        qDebug() << "Questions RAW Response:" << data;
        
        QJsonObject obj = QJsonDocument::fromJson(data).object();
        ActividadConPreguntasDTO act;
        act.id = obj["id"].toVariant().toLongLong();
        act.titulo = obj["titulo"].toString();
        act.descripcion = obj["descripcion"].toString();

        QJsonArray preguntasArr = obj["preguntas"].toArray();
        for (const QJsonValue &pVal : preguntasArr) {
            QJsonObject pObj = pVal.toObject();
            PreguntaDTO p;
            p.id = pObj["id"].toVariant().toLongLong();
            p.enunciado = pObj["enunciado"].toString();
            p.tipo = pObj["tipo"].toString();
            p.archivoUrl = pObj["archivoUrl"].toString();
            p.nombreArchivo = pObj["nombreArchivo"].toString();
            p.archivoDisponible = pObj["archivoDisponible"].toBool();

            QJsonArray opcionesArr = pObj["opciones"].toArray();
            for (const QJsonValue &oVal : opcionesArr) {
                QJsonObject oObj = oVal.toObject();
                OpcionDTO o;
                o.id = oObj["id"].toVariant().toLongLong();
                o.texto = oObj["texto"].toString();
                o.esCorrecta = oObj["esCorrecta"].toBool();
                o.archivoUrl = oObj["archivoUrl"].toString();
                o.nombreArchivo = oObj["nombreArchivo"].toString();
                o.archivoDisponible = oObj["archivoDisponible"].toBool();
                p.opciones.append(o);
            }
            act.preguntas.append(p);
        }
        emit actividadConPreguntasFetched(act);
    });
}

void EstudianteService::resolverActividad(long long estudianteId, long long actividadId, const ActividadResueltaDTO &request, const QString &token)
{
    QUrl url(QString("http://localhost:8080/api/estudiante/%1/actividades/%2/resolver").arg(estudianteId).arg(actividadId));
    
    QJsonObject root;
    root["actividadId"] = request.actividadId;
    root["estudianteId"] = request.estudianteId;
    root["fechaEntrega"] = request.fechaEntrega.toString(Qt::ISODate);
    root["duracionMinutos"] = request.duracionMinutos;

    QJsonArray respuestasArr;
    for (const auto &resp : request.respuestas) {
        QJsonObject rObj;
        rObj["preguntaId"] = resp.preguntaId;
        if (resp.opcionId > 0) rObj["opcionId"] = resp.opcionId;
        if (!resp.respuestaAbierta.isEmpty()) rObj["respuestaAbierta"] = resp.respuestaAbierta;
        respuestasArr.append(rObj);
    }
    root["respuestas"] = respuestasArr;

    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), QJsonDocument(root).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, actividadId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Submit Activity Error [" << actividadId << "]:" << reply->errorString();
            emit errorOccurred(reply->errorString());
            return;
        }

        QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
        ResultadoActividadDTO res;
        res.actividadId = obj["actividadId"].toVariant().toLongLong();
        res.estudianteId = obj["estudianteId"].toVariant().toLongLong();
        res.nota = obj["nota"].toDouble();
        res.observaciones = obj["observaciones"].toString();

        QJsonArray resPregArr = obj["resultadosPreguntas"].toArray();
        for (const QJsonValue &rpVal : resPregArr) {
            QJsonObject rpObj = rpVal.toObject();
            ResultadoPreguntaDTO rp;
            rp.preguntaId = rpObj["preguntaId"].toVariant().toLongLong();
            rp.esCorrecta = rpObj["esCorrecta"].toBool();
            rp.retroalimentacion = rpObj["retroalimentacion"].toString();
            res.resultadosPreguntas.append(rp);
        }
        emit actividadResuelta(res);
    });
}

} // namespace Rep
