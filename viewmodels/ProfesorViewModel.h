#ifndef PROFESORVIEWMODEL_H
#define PROFESORVIEWMODEL_H

#include <QObject>
#include "../api/ProfesorService.h"
#include "../models/ActividadModel.h"
#include "../models/MateriaModel.h"
#include "../models/CursoModel.h"

namespace Rep {

class ProfesorViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(int totalEstudiantes READ totalEstudiantes NOTIFY dashboardDataChanged)
    Q_PROPERTY(int actividadesActivas READ actividadesActivas NOTIFY dashboardDataChanged)
    Q_PROPERTY(int entregasPendientes READ entregasPendientes NOTIFY dashboardDataChanged)
    Q_PROPERTY(ActividadModel* actividadModel READ actividadModel CONSTANT)
    Q_PROPERTY(MateriaModel* materiaModel READ materiaModel CONSTANT)
    Q_PROPERTY(CursoModel* cursoModel READ cursoModel CONSTANT)
    Q_PROPERTY(long long currentActivityId READ currentActivityId WRITE setCurrentActivityId NOTIFY currentActivityChanged)

public:
    explicit ProfesorViewModel(QObject *parent = nullptr);

    bool isLoading() const { return m_isLoading; }
    int totalEstudiantes() const { return m_totalEstudiantes; }
    int actividadesActivas() const { return m_actividadesActivas; }
    int entregasPendientes() const { return m_entregasPendientes; }
    ActividadModel* actividadModel() const { return m_actividadModel; }
    MateriaModel* materiaModel() const { return m_materiaModel; }
    CursoModel* cursoModel() const { return m_cursoModel; }
    long long currentActivityId() const { return m_currentActivityId; }
    void setCurrentActivityId(long long id) { if (m_currentActivityId != id) { m_currentActivityId = id; emit currentActivityChanged(); } }

    Q_INVOKABLE void loadDashboard();
    Q_INVOKABLE void loadMaterias();
    Q_INVOKABLE void loadCursos();
    Q_INVOKABLE void loadActividades(long long materiaId, long long cursoId);
    Q_INVOKABLE void loadEstudiantes(long long cursoId);
    Q_INVOKABLE void loadAsistencia(long long cursoId, long long materiaId, const QDate &fecha);
    Q_INVOKABLE void saveAsistencia(long long cursoId, long long materiaId, const QDate &fecha, const QVariantList &asistencias);
    Q_INVOKABLE void createActividad(const QString &titulo, const QString &tipo, const QString &descripcion, const QDate &fechaEntrega, int duracion, long long materiaId, long long cursoId);
    Q_INVOKABLE void addPregunta(long long actividadId, const QString &enunciado, const QString &tipo, const QVariantList &opciones);

signals:
    void isLoadingChanged();
    void dashboardDataChanged();
    void currentActivityChanged();
    void estudiantesFetched(const QVariantList &estudiantes);
    void asistenciaFetched(const QVariantList &asistencia);
    void asistenciaSaved(bool success);
    void actividadCreada(long long id);
    void preguntaCreada(long long id);
    void errorOccurred(const QString &error);

private:
    ProfesorService *m_service;
    ActividadModel *m_actividadModel;
    MateriaModel *m_materiaModel;
    CursoModel *m_cursoModel;
    bool m_isLoading = false;
    int m_totalEstudiantes = 0;
    int m_actividadesActivas = 0;
    int m_entregasPendientes = 0;
    long long m_currentActivityId = 0;
};

} // namespace Rep

#endif // PROFESORVIEWMODEL_H
