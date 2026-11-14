#ifndef ESTUDIANTEVIEWMODEL_H
#define ESTUDIANTEVIEWMODEL_H

#include <QObject>
#include <QTimer>
#include <QDateTime>
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
    // Modo evaluación: límite de tiempo (0 = sin límite) anclado a la primera apertura
    Q_PROPERTY(int duracionMinutos READ duracionMinutos NOTIFY currentActivityChanged)
    Q_PROPERTY(qint64 limiteEpochMs READ limiteEpochMs NOTIFY currentActivityChanged)
    Q_PROPERTY(bool borradorRecuperado READ borradorRecuperado NOTIFY currentActivityChanged)

public:
    explicit EstudianteViewModel(QObject *parent = nullptr);

    MateriaModel* materiaModel() const { return m_materiaModel; }
    ActividadModel* actividadModel() const { return m_actividadModel; }
    bool isLoading() const { return m_pendingRequests > 0; }

    Q_INVOKABLE void loadMaterias();
    Q_INVOKABLE void loadActividades();
    Q_INVOKABLE void loadActividadesByMateria(long long materiaId);
    Q_INVOKABLE void startActividad(long long actividadId);
    Q_INVOKABLE void submitActividad();

    long long currentActivityId() const { return m_currentActivityId; }
    QString currentActivityTitle() const { return m_currentActivityTitle; }
    QString currentActivityDescription() const { return m_currentActivityDescription; }
    PreguntaModel* preguntaModel() const { return m_preguntaModel; }
    int duracionMinutos() const { return m_duracionMinutos; }
    qint64 limiteEpochMs() const;
    bool borradorRecuperado() const { return m_borradorRecuperado; }

    /** Guarda en disco las respuestas y la hora de inicio de la actividad abierta. */
    Q_INVOKABLE void guardarBorrador();

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
    int m_pendingRequests = 0;
    QDateTime m_activityStartedAt;
    int m_duracionMinutos = 0;
    bool m_borradorRecuperado = false;
    bool m_entregada = false; // tras entregar no se vuelve a crear el borrador
    QTimer *m_autoguardado = nullptr;

    void restaurarBorrador();

    void beginRequest();
    void endRequest();

    long long m_currentActivityId = 0;
    QString m_currentActivityTitle;
    QString m_currentActivityDescription;
};

} // namespace Rep

#endif // ESTUDIANTEVIEWMODEL_H
