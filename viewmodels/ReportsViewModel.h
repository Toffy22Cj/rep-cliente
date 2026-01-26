#ifndef REPORTSVIEWMODEL_H
#define REPORTSVIEWMODEL_H

#include <QObject>
#include <QAbstractListModel>
#include "../api/ProfesorService.h"
#include "../models/ProfesorDTOs.h"

namespace Rep {

class PromediosModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        NombreRole = Qt::UserRole + 1,
        PromedioRole
    };

    explicit PromediosModel(QObject *parent = nullptr);
    void updateData(const QList<ReportePromedioDTO> &data);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

private:
    QList<ReportePromedioDTO> m_data;
};

class EntregasModel : public QAbstractListModel {
    Q_OBJECT
public:

    enum Roles {
        EstudianteRole = Qt::UserRole + 1,
        EstadoRole,
        FechaRole,
        CalificadaRole,
        RespuestaIdRole,
        NotaRole
    };

    explicit EntregasModel(QObject *parent = nullptr);
    void updateData(const QList<ReporteEntregaDTO> &data);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

private:
    QList<ReporteEntregaDTO> m_data;
};

class ReportsViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(PromediosModel* promediosModel READ promediosModel CONSTANT)
    Q_PROPERTY(EntregasModel* entregasModel READ entregasModel CONSTANT)
    Q_PROPERTY(double statPromedio READ statPromedio NOTIFY statsChanged)
    Q_PROPERTY(double statMinima READ statMinima NOTIFY statsChanged)
    Q_PROPERTY(double statMaxima READ statMaxima NOTIFY statsChanged)
    Q_PROPERTY(int statTotalEntregas READ statTotalEntregas NOTIFY statsChanged)
    Q_PROPERTY(int statTotalEstudiantes READ statTotalEstudiantes NOTIFY statsChanged)

public:
    explicit ReportsViewModel(QObject *parent = nullptr);

    PromediosModel* promediosModel() const;
    EntregasModel* entregasModel() const;

    double statPromedio() const;
    double statMinima() const;
    double statMaxima() const;
    int statTotalEntregas() const;
    int statTotalEstudiantes() const;

    Q_INVOKABLE void loadPromedios(long long cursoId, long long materiaId);
    Q_INVOKABLE void loadEntregas(long long actividadId);
    Q_INVOKABLE void loadEstadisticas(long long actividadId);
    Q_INVOKABLE void exportarPromedios(long long cursoId, long long materiaId);
    Q_INVOKABLE void calificar(long long respuestaId, float nota);

signals:
    void statsChanged();
    void errorOccurred(const QString &error);
    void exportCompleted(const QString &path);
    void calificacionCompleted();

private slots:
    void onPromediosFetched(const QList<ReportePromedioDTO> &data);
    void onEntregasFetched(const QList<ReporteEntregaDTO> &data);
    void onEstadisticasFetched(const EstadisticaActividadDTO &stats);
    void onPromediosExported(const QByteArray &data, const QString &filename);

private:
    ProfesorService *m_service;
    PromediosModel *m_promediosModel;
    EntregasModel *m_entregasModel;
    EstadisticaActividadDTO m_stats;
};

} // namespace Rep

#endif // REPORTSVIEWMODEL_H
