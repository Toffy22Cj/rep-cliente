#ifndef PROFESORVIEWMODEL_H
#define PROFESORVIEWMODEL_H

#include <QObject>
#include "../api/ProfesorService.h"
#include "../models/ActividadModel.h"

namespace Rep {

class ProfesorViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(int totalEstudiantes READ totalEstudiantes NOTIFY dashboardDataChanged)
    Q_PROPERTY(int actividadesActivas READ actividadesActivas NOTIFY dashboardDataChanged)
    Q_PROPERTY(int entregasPendientes READ entregasPendientes NOTIFY dashboardDataChanged)
    Q_PROPERTY(ActividadModel* actividadModel READ actividadModel CONSTANT)

public:
    explicit ProfesorViewModel(QObject *parent = nullptr);

    bool isLoading() const { return m_isLoading; }
    int totalEstudiantes() const { return m_totalEstudiantes; }
    int actividadesActivas() const { return m_actividadesActivas; }
    int entregasPendientes() const { return m_entregasPendientes; }
    ActividadModel* actividadModel() const { return m_actividadModel; }

    Q_INVOKABLE void loadDashboard();
    Q_INVOKABLE void loadActividades(long long materiaId, long long cursoId);

signals:
    void isLoadingChanged();
    void dashboardDataChanged();
    void errorOccurred(const QString &error);

private:
    ProfesorService *m_service;
    ActividadModel *m_actividadModel;
    bool m_isLoading = false;
    int m_totalEstudiantes = 0;
    int m_actividadesActivas = 0;
    int m_entregasPendientes = 0;
};

} // namespace Rep

#endif // PROFESORVIEWMODEL_H
