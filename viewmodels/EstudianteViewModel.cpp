#include "EstudianteViewModel.h"
#include "../core/SessionManager.h"

namespace Rep {

EstudianteViewModel::EstudianteViewModel(QObject *parent)
    : QObject(parent),
      m_service(new EstudianteService(this)),
      m_materiaModel(new MateriaModel(this)),
      m_actividadModel(new ActividadModel(this)),
      m_preguntaModel(new PreguntaModel(this))
{
    auto &session = SessionManager::instance();

    connect(m_service, &EstudianteService::materiasFetched, this, [this](const QList<MateriaDTO> &materias) {
        m_materiaModel->setMaterias(materias);
        m_isLoading = false;
        emit isLoadingChanged();
    });

    connect(m_service, &EstudianteService::actividadesFetched, this, [this](const QList<ActividadDTO> &actividades) {
        m_actividadModel->setActividades(actividades);
        m_isLoading = false;
        emit isLoadingChanged();
    });

    connect(m_service, &EstudianteService::actividadConPreguntasFetched, this, [this](const ActividadConPreguntasDTO &act) {
        m_currentActivityId = act.id;
        m_currentActivityTitle = act.titulo;
        m_currentActivityDescription = act.descripcion;
        m_preguntaModel->setQuestions(act.preguntas);
        m_isLoading = false;
        emit isLoadingChanged();
        emit currentActivityChanged();
        emit actividadConPreguntasFetched();
    });

    connect(m_service, &EstudianteService::actividadResuelta, this, [this](const ResultadoActividadDTO &resultado) {
        m_isLoading = false;
        emit isLoadingChanged();
        emit activitySubmitted(true, QString("Actividad enviada con éxito. Nota: %1").arg(resultado.nota));
    });

    connect(m_service, &EstudianteService::errorOccurred, this, [this](const QString &error) {
        m_isLoading = false;
        emit isLoadingChanged();
        
        QString friendlyError = error;
        if (error.contains("status code 403")) {
            friendlyError = "Acceso denegado: Es posible que ya hayas realizado esta actividad o no tengas permiso.";
        } else if (error.contains("status code 401")) {
            friendlyError = "Sesión expirada. Por favor, vuelve a iniciar sesión.";
        }
        
        emit errorOccurred(friendlyError);
    });
}

void EstudianteViewModel::loadMaterias()
{
    if (m_isLoading) return;
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    QString role = session.userRole();
    if (role == "ADMIN" || role == "PROFESOR") {
        emit errorOccurred("Modo vista previa: Los administradores y profesores no tienen materias de estudiante.");
        return;
    }

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchMaterias(session.userId(), session.token());
}

void EstudianteViewModel::loadActividades()
{
    if (m_isLoading) return;
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    QString role = session.userRole();
    if (role == "ADMIN" || role == "PROFESOR") {
        return;
    }

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchActividades(session.userId(), session.token());
}

void EstudianteViewModel::loadActividadesByMateria(long long materiaId)
{
    if (m_isLoading) return;
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchActividadesByMateria(session.userId(), materiaId, session.token());
}

void EstudianteViewModel::startActividad(long long actividadId)
{
    if (m_isLoading) return;
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchActividadConPreguntas(actividadId, session.token());
}

void EstudianteViewModel::submitActividad()
{
    if (m_isLoading) return;
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();

    ActividadResueltaDTO request;
    request.actividadId = m_currentActivityId;
    request.estudianteId = session.userId();
    request.fechaEntrega = QDateTime::currentDateTime();
    request.duracionMinutos = 10; // TODO: Calcular duración real

    for (const auto &p : m_preguntaModel->questions()) {
        RespuestaPreguntaDTO resp;
        resp.preguntaId = p.id;
        resp.opcionId = p.opcionSeleccionadaId;
        resp.respuestaAbierta = p.respuestaAbierta;
        request.respuestas.append(resp);
    }

    m_service->resolverActividad(request.estudianteId, m_currentActivityId, request, session.token());
}

} // namespace Rep
