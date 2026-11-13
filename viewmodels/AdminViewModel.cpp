#include "AdminViewModel.h"
#include "../core/SessionManager.h"

namespace Rep {

// --- UsuarioModel ---
UsuarioModel::UsuarioModel(QObject *parent) : QAbstractListModel(parent) {}
void UsuarioModel::updateData(const QList<UsuarioDTO> &data) {
    beginResetModel();
    m_data = data;
    endResetModel();
}
int UsuarioModel::rowCount(const QModelIndex &) const { return m_data.count(); }
QVariant UsuarioModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_data.size()) return {};
    const auto &item = m_data.at(index.row());
    switch (role) {
    case IdRole: return item.id;
    case NombreRole: return item.nombre;
    case CorreoRole: return item.correo;
    case RolRole: return item.rol;
    case ActivoRole: return item.activo;
    default: return {};
    }
}
QHash<int, QByteArray> UsuarioModel::roleNames() const {
    return { {IdRole, "id"}, {NombreRole, "nombre"}, {CorreoRole, "correo"}, {RolRole, "rol"}, {ActivoRole, "activo"} };
}
QVariantMap UsuarioModel::get(int row) const {
    if (row < 0 || row >= m_data.size()) return {};
    const auto &item = m_data.at(row);
    return { {"id", item.id}, {"nombre", item.nombre}, {"correo", item.correo}, {"rol", item.rol}, {"activo", item.activo} };
}

// --- CursoAdminModel ---
CursoAdminModel::CursoAdminModel(QObject *parent) : QAbstractListModel(parent) {}
void CursoAdminModel::updateData(const QList<CursoAdminDTO> &data) {
    beginResetModel();
    m_data = data;
    endResetModel();
}
int CursoAdminModel::rowCount(const QModelIndex &) const { return m_data.size(); }
QVariant CursoAdminModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_data.size()) return {};
    const auto &item = m_data.at(index.row());
    switch(role) {
    case IdRole: return item.id;
    case GradoRole: return item.grado;
    case GrupoRole: return item.grupo;
    case DisplayNameRole: return QString("%1º %2").arg(item.grado).arg(item.grupo);
    default: return {};
    }
}
QHash<int, QByteArray> CursoAdminModel::roleNames() const {
    return { {IdRole, "id"}, {GradoRole, "grado"}, {GrupoRole, "grupo"}, {DisplayNameRole, "displayName"} };
}
QVariantMap CursoAdminModel::get(int row) const {
    if (row < 0 || row >= m_data.size()) return {};
    const auto &item = m_data.at(row);
    return { {"id", item.id}, {"grado", item.grado}, {"grupo", item.grupo} };
}

// --- MateriaAdminModel ---
MateriaAdminModel::MateriaAdminModel(QObject *parent) : QAbstractListModel(parent) {}
void MateriaAdminModel::updateData(const QList<MateriaAdminDTO> &data) {
    beginResetModel();
    m_data = data;
    endResetModel();
}
int MateriaAdminModel::rowCount(const QModelIndex &) const { return m_data.size(); }
QVariant MateriaAdminModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_data.size()) return {};
    const auto &item = m_data.at(index.row());
    if (role == IdRole) return item.id;
    if (role == NombreRole) return item.nombre;
    return {};
}
QHash<int, QByteArray> MateriaAdminModel::roleNames() const {
    return { {IdRole, "id"}, {NombreRole, "nombre"} };
}
QVariantMap MateriaAdminModel::get(int row) const {
    if (row < 0 || row >= m_data.size()) return {};
    const auto &item = m_data.at(row);
    return { {"id", item.id}, {"nombre", item.nombre} };
}

// --- AsignacionModel ---
AsignacionModel::AsignacionModel(QObject *parent) : QAbstractListModel(parent) {}
void AsignacionModel::updateData(const QList<AsignacionDTO> &data) {
    beginResetModel();
    m_data = data;
    endResetModel();
}
int AsignacionModel::rowCount(const QModelIndex &) const { return m_data.size(); }
QVariant AsignacionModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_data.size()) return {};
    const auto &item = m_data.at(index.row());
    switch(role) {
    case IdRole: return item.id;
    case ProfesorIdRole: return item.profesorId;
    case ProfesorNombreRole: return item.profesorNombre;
    case MateriaIdRole: return item.materiaId;
    case MateriaNombreRole: return item.materiaNombre;
    case CursoIdRole: return item.cursoId;
    case CursoNombreRole: return item.cursoNombre;
    default: return {};
    }
}
QHash<int, QByteArray> AsignacionModel::roleNames() const {
    return { 
        {IdRole, "id"}, 
        {ProfesorIdRole, "profesorId"}, {ProfesorNombreRole, "profesorNombre"}, 
        {MateriaIdRole, "materiaId"}, {MateriaNombreRole, "materiaNombre"},
        {CursoIdRole, "cursoId"}, {CursoNombreRole, "cursoNombre"}
    };
}
QVariantMap AsignacionModel::get(int row) const {
    if (row < 0 || row >= m_data.size()) return {};
    const auto &item = m_data.at(row);
    return { 
        {"id", item.id}, 
        {"profesorId", item.profesorId}, {"profesorNombre", item.profesorNombre}, 
        {"materiaId", item.materiaId}, {"materiaNombre", item.materiaNombre},
        {"cursoId", item.cursoId}, {"cursoNombre", item.cursoNombre}
    };
}

// --- AdminViewModel ---

AdminViewModel::AdminViewModel(QObject *parent)
    : QObject(parent),
      m_service(new AdminService(this)),
      m_usuarioModel(new UsuarioModel(this)),
      m_cursoModel(new CursoAdminModel(this)),
      m_materiaModel(new MateriaAdminModel(this)),
      m_asignacionModel(new AsignacionModel(this))
{
    connect(m_service, &AdminService::usuariosFetched, this, &AdminViewModel::onUsuariosFetched);
    connect(m_service, &AdminService::cursosFetched, this, &AdminViewModel::onCursosFetched);
    connect(m_service, &AdminService::materiasFetched, this, &AdminViewModel::onMateriasFetched);
    connect(m_service, &AdminService::asignacionesFetched, this, &AdminViewModel::onAsignacionesFetched);
    
    connect(m_service, &AdminService::operationSuccess, this, &AdminViewModel::operationSuccess);
    connect(m_service, &AdminService::errorOccurred, this, &AdminViewModel::errorOccurred);
}

UsuarioModel* AdminViewModel::usuarioModel() const { return m_usuarioModel; }
CursoAdminModel* AdminViewModel::cursoModel() const { return m_cursoModel; }
MateriaAdminModel* AdminViewModel::materiaModel() const { return m_materiaModel; }
AsignacionModel* AdminViewModel::asignacionModel() const { return m_asignacionModel; }

void AdminViewModel::loadUsuarios() {
    m_service->fetchUsuarios(SessionManager::instance().token());
}
void AdminViewModel::loadCursos() {
    m_service->fetchCursos(SessionManager::instance().token());
}
void AdminViewModel::loadMaterias() {
    m_service->fetchMaterias(SessionManager::instance().token());
}
void AdminViewModel::loadAsignaciones() {
    m_service->fetchAsignaciones(SessionManager::instance().token());
}

void AdminViewModel::saveUsuario(long long id, const QString &nombre, const QString &correo, const QString &rol, const QString &password, bool activo) {
    UsuarioDTO u;
    u.id = id;
    u.nombre = nombre;
    u.correo = correo;
    u.rol = rol;
    u.activo = activo;
    u.password = password;
    
    if (id > 0) m_service->updateUsuario(u, SessionManager::instance().token());
    // Create not implemented yet in this iteration, focus on update
}

void AdminViewModel::deleteUsuario(long long id) {
    m_service->deleteUsuario(id, SessionManager::instance().token());
}

void AdminViewModel::toggleUsuarioEstado(long long id, bool activo) {
    m_service->toggleUsuarioEstado(id, activo, SessionManager::instance().token());
}

void AdminViewModel::createCurso(int grado, const QString &grupo) {
    CursoAdminDTO c; c.grado = grado; c.grupo = grupo;
    m_service->createCurso(c, SessionManager::instance().token());
}

void AdminViewModel::updateCurso(long long id, int grado, const QString &grupo) {
    CursoAdminDTO c; c.id = id; c.grado = grado; c.grupo = grupo;
    m_service->updateCurso(c, SessionManager::instance().token());
}

void AdminViewModel::deleteCurso(long long id) {
    m_service->deleteCurso(id, SessionManager::instance().token());
}

void AdminViewModel::createMateria(const QString &nombre) {
    MateriaAdminDTO m; m.nombre = nombre;
    m_service->createMateria(m, SessionManager::instance().token());
}

void AdminViewModel::updateMateria(long long id, const QString &nombre) {
    MateriaAdminDTO m; m.id = id; m.nombre = nombre;
    m_service->updateMateria(m, SessionManager::instance().token());
}

void AdminViewModel::deleteMateria(long long id) {
    m_service->deleteMateria(id, SessionManager::instance().token());
}

void AdminViewModel::createAsignacion(long long profesorId, long long materiaId, long long cursoId) {
    m_service->createAsignacion(profesorId, materiaId, cursoId, SessionManager::instance().token());
}

void AdminViewModel::deleteAsignacion(long long id) {
    m_service->deleteAsignacion(id, SessionManager::instance().token());
}

// Slots
void AdminViewModel::onUsuariosFetched(const QList<UsuarioDTO> &data) { m_usuarioModel->updateData(data); }
void AdminViewModel::onCursosFetched(const QList<CursoAdminDTO> &data) { m_cursoModel->updateData(data); }
void AdminViewModel::onMateriasFetched(const QList<MateriaAdminDTO> &data) { m_materiaModel->updateData(data); }
void AdminViewModel::onAsignacionesFetched(const QList<AsignacionDTO> &data) { m_asignacionModel->updateData(data); }

} // namespace Rep
