#ifndef ESTUDIANTESERVICE_H
#define ESTUDIANTESERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include "../models/StudentDTOs.h"

namespace Rep {

class EstudianteService : public QObject
{
    Q_OBJECT
public:
    explicit EstudianteService(QObject *parent = nullptr);

    void fetchMaterias(long long estudianteId, const QString &token);
    void fetchActividades(long long estudianteId, const QString &token);
    void fetchActividadesByMateria(long long estudianteId, long long materiaId, const QString &token);
    void fetchActividadConPreguntas(long long actividadId, const QString &token);
    void resolverActividad(long long estudianteId, long long actividadId, const ActividadResueltaDTO &request, const QString &token);

signals:
    void materiasFetched(const QList<MateriaDTO> &materias);
    void actividadesFetched(const QList<ActividadDTO> &actividades);
    void actividadConPreguntasFetched(const ActividadConPreguntasDTO &actividad);
    void actividadResuelta(const ResultadoActividadDTO &resultado);
    void errorOccurred(const QString &error);

private:
    QNetworkAccessManager *m_networkManager;
    QNetworkRequest createRequest(const QUrl &url, const QString &token);
};

} // namespace Rep

#endif // ESTUDIANTESERVICE_H
