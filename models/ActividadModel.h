#ifndef ACTIVIDADMODEL_H
#define ACTIVIDADMODEL_H

#include <QAbstractListModel>
#include "../models/StudentDTOs.h"

namespace Rep {

class ActividadModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        TituloRole,
        TipoRole,
        DescripcionRole,
        FechaEntregaRole,
        MateriaNombreRole,
        CursoNombreRole,
        MateriaRole,
        DuracionRole
    };

    explicit ActividadModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}

    int rowCount(const QModelIndex &parent = QModelIndex()) const override { return m_data.size(); }
    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_data.size()) return {};
        const auto &item = m_data[index.row()];
        switch (role) {
            case IdRole: return item.id;
            case TituloRole: return item.titulo;
            case TipoRole: return item.tipo;
            case DescripcionRole: return item.descripcion;
            case FechaEntregaRole: return item.fechaEntrega.toString(Qt::ISODate);
            case MateriaNombreRole: return item.materiaNombre;
            case CursoNombreRole: return item.cursoNombre;
            case MateriaRole: return item.materiaNombre; // Alias for QML
            case DuracionRole: return item.duracionMinutos;
            default: return {};
        }
    }
    QHash<int, QByteArray> roleNames() const override {
        return {
            {IdRole, "id"},
            {TituloRole, "titulo"},
            {TipoRole, "tipo"},
            {DescripcionRole, "descripcion"},
            {FechaEntregaRole, "fechaEntrega"},
            {MateriaNombreRole, "materiaNombre"},
            {CursoNombreRole, "cursoNombre"},
            {MateriaRole, "materia"},
            {DuracionRole, "duracion"}
        };
    }

    void setActividades(const QList<ActividadDTO> &data) {
        if (m_data.size() == data.size() && data.isEmpty()) return; // check redundancy slightly
        beginResetModel();
        m_data = data;
        endResetModel();
        emit countChanged();
    }
    void setData(const QList<ActividadDTO> &data) { setActividades(data); }

    Q_INVOKABLE QVariantMap get(int row) const {
        if (row < 0 || row >= m_data.size()) return {};
        const auto &item = m_data.at(row);
        return {
            {"id", item.id},
            {"titulo", item.titulo},
            {"tipo", item.tipo},
            {"descripcion", item.descripcion},
            {"fechaEntrega", item.fechaEntrega.toString(Qt::ISODate)},
            {"duracion", item.duracionMinutos},
            {"materiaId", item.materiaId},
            {"cursoId", item.cursoId}
        };
    }

signals:
    void countChanged();

private:
    QList<ActividadDTO> m_data;
};

} // namespace Rep

#endif // ACTIVIDADMODEL_H
