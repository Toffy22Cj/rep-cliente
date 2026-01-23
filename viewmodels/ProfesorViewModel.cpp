#include "ProfesorViewModel.h"
#include "../core/SessionManager.h"

namespace Rep {

ProfesorViewModel::ProfesorViewModel(QObject *parent)
    : QObject(parent), 
      m_service(new ProfesorService(this)),
      m_actividadModel(new ActividadModel(this)),
      m_materiaModel(new MateriaModel(this)),
      m_cursoModel(new CursoModel(this))
{
    connect(m_service, &ProfesorService::dashboardDataFetched, this, [this](const ProfesorDashboardDTO &data) {
        m_totalEstudiantes = data.totalEstudiantes;
        m_actividadesActivas = data.actividadesActivas;
        m_entregasPendientes = data.entregasPendientes;
        
        // Update models if dashboard includes them
        QList<MateriaDTO> materias;
        for (const auto &m : data.materias) {
            materias.append({m.id, m.nombre});
        }
        m_materiaModel->setMaterias(materias);

        m_isLoading = false;
        emit isLoadingChanged();
        emit dashboardDataChanged();
    });

    connect(m_service, &ProfesorService::cursosFetched, this, [this](const QList<CursoDTO> &cursos) {
        m_cursoModel->setCursos(cursos);
        m_isLoading = false;
        emit isLoadingChanged();
    });

    connect(m_service, &ProfesorService::materiasAsignadasFetched, this, [this](const QList<MateriaAsignadaDTO> &materias) {
        QList<MateriaDTO> list;
        for (const auto &m : materias) {
            list.append({m.id, m.nombre});
        }
        m_materiaModel->setMaterias(list);
        m_isLoading = false;
        emit isLoadingChanged();
    });

    connect(m_service, &ProfesorService::actividadesFetched, this, [this](const QList<ActividadDTO> &actividades) {
        m_actividadModel->setActividades(actividades);
        m_isLoading = false;
        emit isLoadingChanged();
    });

    connect(m_service, &ProfesorService::errorOccurred, this, [this](const QString &error) {
        m_isLoading = false;
        emit isLoadingChanged();
        emit errorOccurred(error);
    });

    connect(m_service, &ProfesorService::estudiantesFetched, this, [this](const QList<EstudianteSimplificadoDTO> &estudiantes) {
        QVariantList list;
        for (const auto &e : estudiantes) {
            QVariantMap map;
            map["id"] = e.id;
            map["nombre"] = e.nombre;
            map["identificacion"] = e.identificacion;
            map["correo"] = e.correo;
            list.append(map);
        }
        m_isLoading = false;
        emit isLoadingChanged();
        emit estudiantesFetched(list);
    });

    connect(m_service, &ProfesorService::asistenciaFetched, this, [this](const QList<AsistenciaDTO> &asistencia) {
        QVariantList list;
        for (const auto &a : asistencia) {
            QVariantMap map;
            map["estudianteId"] = a.estudianteId;
            map["nombreEstudiante"] = a.nombreEstudiante;
            map["asistio"] = a.asistio;
            map["observaciones"] = a.observaciones;
            list.append(map);
        }
        m_isLoading = false;
        emit isLoadingChanged();
        emit asistenciaFetched(list);
    });

    connect(m_service, &ProfesorService::asistenciaSaved, this, &ProfesorViewModel::asistenciaSaved);
    connect(m_service, &ProfesorService::actividadCreada, this, &ProfesorViewModel::actividadCreada);
    connect(m_service, &ProfesorService::preguntaCreada, this, &ProfesorViewModel::preguntaCreada);
}

void ProfesorViewModel::loadDashboard()
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchDashboardData(session.token());
}

void ProfesorViewModel::loadMaterias()
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchMateriasAsignadas(session.token());
}

void ProfesorViewModel::loadCursos()
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchCursos(session.token());
}

void ProfesorViewModel::loadActividades(long long materiaId, long long cursoId)
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchActividades(materiaId, cursoId, session.token());
}

void ProfesorViewModel::loadEstudiantes(long long cursoId)
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchEstudiantes(cursoId, session.token());
}

void ProfesorViewModel::loadAsistencia(long long cursoId, long long materiaId, const QDate &fecha)
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchAsistencia(cursoId, materiaId, fecha, session.token());
}

void ProfesorViewModel::saveAsistencia(long long cursoId, long long materiaId, const QDate &fecha, const QVariantList &asistencias)
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    QList<AsistenciaDTO> list;
    for (const auto &v : asistencias) {
        QVariantMap map = v.toMap();
        list.append({
            map["estudianteId"].toLongLong(),
            map["nombreEstudiante"].toString(),
            map["asistio"].toBool(),
            map["observaciones"].toString()
        });
    }

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->saveAsistencia(cursoId, materiaId, fecha, list, session.token());
}

void ProfesorViewModel::createActividad(const QString &titulo, const QString &tipo, const QString &descripcion, const QDate &fechaEntrega, int duracion, long long materiaId, long long cursoId)
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    ActividadCreateDTO act;
    act.titulo = titulo;
    act.tipo = tipo;
    act.descripcion = descripcion;
    act.fechaEntrega = fechaEntrega;
    act.duracionMinutos = duracion;
    act.materiaId = materiaId;
    act.cursoId = cursoId;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->crearActividad(act, session.token());
}

void ProfesorViewModel::addPregunta(long long actividadId, const QString &enunciado, const QString &tipo, const QVariantList &opciones)
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    PreguntaRequestDTO p;
    p.actividadId = actividadId;
    p.enunciado = enunciado;
    p.tipo = tipo;
    
    for (const auto &v : opciones) {
        QVariantMap map = v.toMap();
        p.opciones.append({map["texto"].toString(), map["esCorrecta"].toBool()});
    }

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->crearPregunta(p, session.token());
}

} // namespace Rep
