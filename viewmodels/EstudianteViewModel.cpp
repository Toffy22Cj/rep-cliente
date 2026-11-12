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
        endRequest();
    });

    connect(m_service, &EstudianteService::actividadesFetched, this, [this](const QList<ActividadDTO> &actividades) {
        m_actividadModel->setActividades(actividades);
        endRequest();
    });

    connect(m_service, &EstudianteService::actividadConPreguntasFetched, this, [this](const ActividadConPreguntasDTO &act) {
        m_currentActivityId = act.id;
        m_currentActivityTitle = act.titulo;
        m_currentActivityDescription = act.descripcion;
        m_preguntaModel->setQuestions(act.preguntas);
        m_activityStartedAt = QDateTime::currentDateTime();
        endRequest();
        emit currentActivityChanged();
        emit actividadConPreguntasFetched();
    });

    connect(m_service, &EstudianteService::actividadResuelta, this, [this](const ResultadoActividadDTO &resultado) {
        endRequest();
        emit activitySubmitted(true, QString("Actividad enviada con éxito. Nota: %1").arg(resultado.nota));
    });

    // HttpClient ya traduce el error (incluido el mensaje del servidor y la sesión expirada)
    connect(m_service, &EstudianteService::errorOccurred, this, [this](const QString &error) {
        endRequest();
        emit errorOccurred(error);
    });
}

/*
 * Varias cargas pueden estar en curso a la vez (materias + actividades al abrir el
 * dashboard). Antes un único booleano hacía que la segunda carga se descartara y las
 * actividades no aparecían. Ahora se cuenta el número de peticiones pendientes.
 */
void EstudianteViewModel::beginRequest()
{
    if (m_pendingRequests++ == 0)
        emit isLoadingChanged();
}

void EstudianteViewModel::endRequest()
{
    if (m_pendingRequests > 0 && --m_pendingRequests == 0)
        emit isLoadingChanged();
}

void EstudianteViewModel::loadMaterias()
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    QString role = session.userRole();
    if (role == "ADMIN" || role == "PROFESOR") {
        emit errorOccurred("Modo vista previa: Los administradores y profesores no tienen materias de estudiante.");
        return;
    }

    beginRequest();
    m_service->fetchMaterias(session.userId(), session.token());
}

void EstudianteViewModel::loadActividades()
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    QString role = session.userRole();
    if (role == "ADMIN" || role == "PROFESOR") {
        return;
    }

    beginRequest();
    m_service->fetchActividades(session.userId(), session.token());
}

void EstudianteViewModel::loadActividadesByMateria(long long materiaId)
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    beginRequest();
    m_service->fetchActividadesByMateria(session.userId(), materiaId, session.token());
}

void EstudianteViewModel::startActividad(long long actividadId)
{
    if (isLoading()) return; // evita abrir dos veces la misma actividad
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    beginRequest();
    m_service->fetchActividadConPreguntas(actividadId, session.token());
}

void EstudianteViewModel::submitActividad()
{
    if (isLoading()) return; // evita envíos duplicados
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    beginRequest();

    ActividadResueltaDTO request;
    request.actividadId = m_currentActivityId;
    request.estudianteId = session.userId();
    request.fechaEntrega = QDateTime::currentDateTime();
    request.duracionMinutos = m_activityStartedAt.isValid()
        ? qMax<qint64>(1, m_activityStartedAt.secsTo(request.fechaEntrega) / 60)
        : 0;

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
