#include "ProfesorViewModel.h"
#include "../core/SessionManager.h"

namespace Rep {

ProfesorViewModel::ProfesorViewModel(QObject *parent)
    : QObject(parent), 
      m_service(new ProfesorService(this)),
      m_actividadModel(new ActividadModel(this))
{
    connect(m_service, &ProfesorService::dashboardDataFetched, this, [this](const ProfesorDashboardDTO &data) {
        m_totalEstudiantes = data.totalEstudiantes;
        m_actividadesActivas = data.actividadesActivas;
        m_entregasPendientes = data.entregasPendientes;
        m_isLoading = false;
        emit isLoadingChanged();
        emit dashboardDataChanged();
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
}

void ProfesorViewModel::loadDashboard()
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchDashboardData(session.token());
}

void ProfesorViewModel::loadActividades(long long materiaId, long long cursoId)
{
    auto &session = SessionManager::instance();
    if (!session.isAuthenticated()) return;

    m_isLoading = true;
    emit isLoadingChanged();
    m_service->fetchActividades(materiaId, cursoId, session.token());
}

} // namespace Rep
