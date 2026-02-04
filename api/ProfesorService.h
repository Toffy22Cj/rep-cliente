#ifndef PROFESORSERVICE_H
#define PROFESORSERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include "../models/ProfesorDTOs.h"
#include "../models/StudentDTOs.h"

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
    void fetchEstudiantes(long long cursoId, const QString &token);
    void fetchAsistencia(long long cursoId, long long materiaId, const QDate &fecha, const QString &token);
    void saveAsistencia(long long cursoId, long long materiaId, const QDate &fecha, const QList<AsistenciaDTO> &asistencia, const QString &token);
    
    // Reportes
    void fetchPromedios(long long cursoId, long long materiaId, const QString &token);
    void fetchEntregas(long long actividadId, const QString &token);
    void fetchEstadisticasActividad(long long actividadId, const QString &token);
    void exportPromedios(long long cursoId, long long materiaId, const QString &token);
    void crearActividad(const ActividadCreateDTO &actividad, const QString &token);
    void actualizarActividad(long long id, const ActividadCreateDTO &actividad, const QString &token);
    void crearPregunta(const PreguntaRequestDTO &pregunta, const QString &token);

signals:
    void dashboardDataFetched(const ProfesorDashboardDTO &data);
    void materiasAsignadasFetched(const QList<MateriaAsignadaDTO> &materias);
    void cursosFetched(const QList<CursoDTO> &cursos);
    void actividadesFetched(const QList<ActividadDTO> &actividades);
    void respuestasFetched(const QList<RespuestaEstudianteSimplificadaDTO> &respuestas);
    void respuestaCalificada(long long respuestaId, float nota);
    void estudiantesFetched(const QList<EstudianteSimplificadoDTO> &estudiantes);
    void asistenciaFetched(const QList<AsistenciaDTO> &asistencia);
    void asistenciaSaved(bool success);

    // Signals Reportes
    void promediosFetched(const QList<ReportePromedioDTO> &promedios);
    void entregasFetched(const QList<ReporteEntregaDTO> &entregas);
    void estadisticasFetched(const EstadisticaActividadDTO &estadisticas);
    void promediosExported(const QByteArray &pdfData, const QString &filename);
    void actividadCreada(long long id);
    void actividadActualizada(bool success);
    void preguntaCreada(long long id);

    void errorOccurred(const QString &error);

private:
    QNetworkAccessManager *m_networkManager;
    QNetworkRequest createRequest(const QUrl &url, const QString &token);
};

} // namespace Rep

#endif // PROFESORSERVICE_H
