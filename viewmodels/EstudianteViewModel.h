#ifndef ESTUDIANTEVIEWMODEL_H
#define ESTUDIANTEVIEWMODEL_H

#include <QObject>
#include "../api/EstudianteService.h"
#include "../models/MateriaModel.h"
#include "../models/ActividadModel.h"
#include "../models/PreguntaModel.h"

namespace Rep {

class EstudianteViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MateriaModel* materiaModel READ materiaModel CONSTANT)
    Q_PROPERTY(ActividadModel* actividadModel READ actividadModel CONSTANT)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(long long currentActivityId READ currentActivityId NOTIFY currentActivityChanged)
    Q_PROPERTY(QString currentActivityTitle READ currentActivityTitle NOTIFY currentActivityChanged)
    Q_PROPERTY(QString currentActivityDescription READ currentActivityDescription NOTIFY currentActivityChanged)
    Q_PROPERTY(PreguntaModel* preguntaModel READ preguntaModel CONSTANT)

public:
    explicit EstudianteViewModel(QObject *parent = nullptr);

    MateriaModel* materiaModel() const { return m_materiaModel; }
    ActividadModel* actividadModel() const { return m_actividadModel; }
    bool isLoading() const { return m_isLoading; }

    Q_INVOKABLE void loadMaterias();
    Q_INVOKABLE void loadActividades();
    Q_INVOKABLE void loadActividadesByMateria(long long materiaId);
    Q_INVOKABLE void startActividad(long long actividadId);
    Q_INVOKABLE void submitActividad();

    long long currentActivityId() const { return m_currentActivityId; }
    QString currentActivityTitle() const { return m_currentActivityTitle; }
    QString currentActivityDescription() const { return m_currentActivityDescription; }
    PreguntaModel* preguntaModel() const { return m_preguntaModel; }

signals:
    void isLoadingChanged();
    void currentActivityChanged();
    void actividadConPreguntasFetched();
    void activitySubmitted(bool success, const QString &message);
    void errorOccurred(const QString &error);

private:
    EstudianteService *m_service;
    MateriaModel *m_materiaModel;
    ActividadModel *m_actividadModel;
    PreguntaModel *m_preguntaModel;
    bool m_isLoading = false;

    long long m_currentActivityId = 0;
    QString m_currentActivityTitle;
    QString m_currentActivityDescription;
};

} // namespace Rep

#endif // ESTUDIANTEVIEWMODEL_H
