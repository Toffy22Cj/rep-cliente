#include "EstudianteViewModel.h"
#include "../core/SessionManager.h"
#include "../core/AlmacenLocal.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

namespace Rep {

EstudianteViewModel::EstudianteViewModel(QObject *parent)
    : QObject(parent),
      m_service(new EstudianteService(this)),
      m_materiaModel(new MateriaModel(this)),
      m_actividadModel(new ActividadModel(this)),
      m_preguntaModel(new PreguntaModel(this))
{
    auto &session = SessionManager::instance();

    // Autoguardado: cada cambio de respuesta se escribe en disco (agrupado cada 0,5 s)
    m_autoguardado = new QTimer(this);
    m_autoguardado->setSingleShot(true);
    m_autoguardado->setInterval(500);
    connect(m_autoguardado, &QTimer::timeout, this, &EstudianteViewModel::guardarBorrador);
    connect(m_preguntaModel, &QAbstractItemModel::dataChanged, m_autoguardado, qOverload<>(&QTimer::start));

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
        m_duracionMinutos = act.duracionMinutos;
        m_preguntaModel->setQuestions(act.preguntas);
        restaurarBorrador();
        endRequest();
        emit currentActivityChanged();
        emit actividadConPreguntasFetched();
    });

    connect(m_service, &EstudianteService::actividadResuelta, this, [this](const ResultadoActividadDTO &resultado) {
        m_entregada = true;
        AlmacenLocal::eliminarBorrador(m_currentActivityId);
        endRequest();
        emit activitySubmitted(true, QString("Actividad enviada con éxito. Nota: %1").arg(resultado.nota));
    });

    connect(m_service, &EstudianteService::actividadEncolada, this, [this](long long) {
        // La entrega ya está en la cola persistente; el borrador ya no hace falta
        m_entregada = true;
        AlmacenLocal::eliminarBorrador(m_currentActivityId);
        endRequest();
        emit activitySubmitted(true, tr("Sin conexión: tu entrega quedó guardada en este equipo y se enviará "
                                        "automáticamente cuando vuelva la conexión. Si el plazo vence antes, "
                                        "el servidor podría rechazarla."));
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

qint64 EstudianteViewModel::limiteEpochMs() const
{
    if (m_duracionMinutos <= 0 || !m_activityStartedAt.isValid())
        return 0;
    return m_activityStartedAt.addSecs(qint64(m_duracionMinutos) * 60).toMSecsSinceEpoch();
}

/*
 * Si existe un borrador (la app se cerró, se fue la luz…), recupera las respuestas y la
 * hora de inicio original: reabrir la actividad no reinicia el reloj. Si no existe, lo
 * crea ya con la hora de inicio.
 */
void EstudianteViewModel::restaurarBorrador()
{
    m_borradorRecuperado = false;
    m_entregada = false;
    m_activityStartedAt = QDateTime::currentDateTime();

    if (const auto datos = AlmacenLocal::leerBorrador(m_currentActivityId)) {
        const QJsonObject obj = QJsonDocument::fromJson(*datos).object();
        const QDateTime inicio = QDateTime::fromString(obj["iniciadaEn"].toString(), Qt::ISODate);
        if (inicio.isValid())
            m_activityStartedAt = inicio;

        QHash<long long, QJsonObject> porPregunta;
        for (const QJsonValue &v : obj["respuestas"].toArray()) {
            const QJsonObject r = v.toObject();
            porPregunta.insert(r["preguntaId"].toVariant().toLongLong(), r);
        }
        const auto &preguntas = m_preguntaModel->questions();
        for (int i = 0; i < preguntas.size(); ++i) {
            const auto it = porPregunta.constFind(preguntas[i].id);
            if (it == porPregunta.constEnd())
                continue;
            const long long opcion = it->value("opcionId").toVariant().toLongLong();
            if (opcion > 0)
                m_preguntaModel->selectOpcion(i, opcion);
            const QString abierta = it->value("respuestaAbierta").toString();
            if (!abierta.isEmpty())
                m_preguntaModel->setRespuestaAbierta(i, abierta);
            m_borradorRecuperado = true;
        }
    }
    m_autoguardado->stop();
    guardarBorrador();
}

void EstudianteViewModel::guardarBorrador()
{
    if (m_currentActivityId <= 0 || m_entregada)
        return;
    QJsonArray respuestas;
    for (const auto &p : m_preguntaModel->questions()) {
        if (p.opcionSeleccionadaId <= 0 && p.respuestaAbierta.isEmpty())
            continue;
        respuestas.append(QJsonObject{
            {"preguntaId", QString::number(p.id)},
            {"opcionId", QString::number(p.opcionSeleccionadaId)},
            {"respuestaAbierta", p.respuestaAbierta}});
    }
    const QJsonObject obj{
        {"actividadId", QString::number(m_currentActivityId)},
        {"iniciadaEn", m_activityStartedAt.toString(Qt::ISODateWithMs)},
        {"respuestas", respuestas}};
    AlmacenLocal::guardarBorrador(m_currentActivityId, QJsonDocument(obj).toJson(QJsonDocument::Compact));
}

} // namespace Rep
