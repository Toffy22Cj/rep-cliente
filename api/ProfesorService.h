#ifndef PROFESORSERVICE_H
#define PROFESORSERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include "ProfesorDTOs.h"
#include "StudentDTOs.h"

namespace Rep {

class ProfesorService : public QObject
{
    Q_OBJECT
public:
    explicit ProfesorService(QObject *parent = nullptr);

    void fetchDashboardData(const QString &token);
    void fetchMateriasAsignadas(const QString &token);
    void fetchCursos(const QString &token);
    void fetchActividades(long long materiaId, long long cursoId, const QString &token);
    void fetchRespuestas(long long actividadId, const QString &token);
    void calificarRespuesta(long long respuestaId, float nota, const QString &token);

signals:
    void dashboardDataFetched(const ProfesorDashboardDTO &data);
    void materiasAsignadasFetched(const QList<MateriaAsignadaDTO> &materias);
    void cursosFetched(const QList<CursoDTO> &cursos);
    void actividadesFetched(const QList<ActividadDTO> &actividades);
    void respuestasFetched(const QList<RespuestaEstudianteSimplificadaDTO> &respuestas);
    void respuestaCalificada(long long respuestaId, float nota);
    void errorOccurred(const QString &error);

private:
    QNetworkAccessManager *m_networkManager;
    QNetworkRequest createRequest(const QUrl &url, const QString &token);
};

} // namespace Rep

#endif // PROFESORSERVICE_H
