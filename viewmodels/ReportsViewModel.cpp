#include "ReportsViewModel.h"
#include "../core/SessionManager.h"
#include <QStandardPaths>
#include <QFile>
#include <QDir>
#include <QDebug>

namespace Rep {

// --- PromediosModel ---

PromediosModel::PromediosModel(QObject *parent) : QAbstractListModel(parent) {}

void PromediosModel::updateData(const QList<ReportePromedioDTO> &data) {
    beginResetModel();
    m_data = data;
    endResetModel();
}

int PromediosModel::rowCount(const QModelIndex &) const {
    return m_data.count();
}

QVariant PromediosModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_data.size()) return QVariant();
    const auto &item = m_data.at(index.row());
    
    switch (role) {
    case NombreRole: return item.estudianteNombre;
    case PromedioRole: return item.promedio;
    default: return QVariant();
    }
}

QHash<int, QByteArray> PromediosModel::roleNames() const {
    return { {NombreRole, "nombre"}, {PromedioRole, "promedio"} };
}

// --- EntregasModel ---

EntregasModel::EntregasModel(QObject *parent) : QAbstractListModel(parent) {}

void EntregasModel::updateData(const QList<ReporteEntregaDTO> &data) {
    beginResetModel();
    m_data = data;
    endResetModel();
}

int EntregasModel::rowCount(const QModelIndex &) const {
    return m_data.count();
}

QVariant EntregasModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_data.size()) return QVariant();
    const auto &item = m_data.at(index.row());

    switch (role) {
    case EstudianteRole: return item.estudianteNombre;

    case FechaRole: return item.fechaEntrega.isValid() ? item.fechaEntrega.toString("dd/MM/yyyy HH:mm") : "---";
    case CalificadaRole: return item.calificada;
    case RespuestaIdRole: return QVariant::fromValue(item.respuestaId);
    case NotaRole: return item.nota;
    default: return QVariant();
    }
}

QHash<int, QByteArray> EntregasModel::roleNames() const {
    return {
        {EstudianteRole, "estudiante"},
        {EstadoRole, "estado"},
        {FechaRole, "fecha"},
        {CalificadaRole, "calificada"},
        {RespuestaIdRole, "respuestaId"},
        {NotaRole, "nota"}
    };
}

// --- ReportsViewModel ---

ReportsViewModel::ReportsViewModel(QObject *parent)
    : QObject(parent),
      m_service(new ProfesorService(this)),
      m_promediosModel(new PromediosModel(this)),
      m_entregasModel(new EntregasModel(this))
{
    m_stats = {0, 0, 0, 0, 0};

    connect(m_service, &ProfesorService::promediosFetched, this, &ReportsViewModel::onPromediosFetched);
    connect(m_service, &ProfesorService::entregasFetched, this, &ReportsViewModel::onEntregasFetched);
    connect(m_service, &ProfesorService::estadisticasFetched, this, &ReportsViewModel::onEstadisticasFetched);
    connect(m_service, &ProfesorService::promediosExported, this, &ReportsViewModel::onPromediosExported);
    
    connect(m_service, &ProfesorService::respuestaCalificada, this, [this]() {
         emit calificacionCompleted();
    });
}

PromediosModel* ReportsViewModel::promediosModel() const { return m_promediosModel; }
EntregasModel* ReportsViewModel::entregasModel() const { return m_entregasModel; }

double ReportsViewModel::statPromedio() const { return m_stats.promedio; }
double ReportsViewModel::statMinima() const { return m_stats.notaMinima; }
double ReportsViewModel::statMaxima() const { return m_stats.notaMaxima; }
int ReportsViewModel::statTotalEntregas() const { return m_stats.totalEntregas; }
int ReportsViewModel::statTotalEstudiantes() const { return m_stats.totalEstudiantes; }

void ReportsViewModel::loadPromedios(long long cursoId, long long materiaId) {
    m_service->fetchPromedios(cursoId, materiaId, SessionManager::instance().token());
}

void ReportsViewModel::loadEntregas(long long actividadId) {
    m_service->fetchEntregas(actividadId, SessionManager::instance().token());
}

void ReportsViewModel::loadEstadisticas(long long actividadId) {
    m_service->fetchEstadisticasActividad(actividadId, SessionManager::instance().token());
}

void ReportsViewModel::exportarPromedios(long long cursoId, long long materiaId) {
    m_service->exportPromedios(cursoId, materiaId, SessionManager::instance().token());
}

void ReportsViewModel::calificar(long long respuestaId, float nota) {
    m_service->calificarRespuesta(respuestaId, nota, SessionManager::instance().token());
}

void ReportsViewModel::onPromediosFetched(const QList<ReportePromedioDTO> &data) {
    m_promediosModel->updateData(data);
}

void ReportsViewModel::onEntregasFetched(const QList<ReporteEntregaDTO> &data) {
    m_entregasModel->updateData(data);
}

void ReportsViewModel::onEstadisticasFetched(const EstadisticaActividadDTO &stats) {
    m_stats = stats;
    emit statsChanged();
}

void ReportsViewModel::onPromediosExported(const QByteArray &data, const QString &filename) {
    QString downloadPath = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    QString fullPath = QDir(downloadPath).filePath(filename);
    
    QFile file(fullPath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(data);
        file.close();
        emit exportCompleted("Archivo guardado en: " + fullPath);
    } else {
        emit errorOccurred("No se pudo guardar el archivo en " + fullPath);
    }
}

} // namespace Rep
