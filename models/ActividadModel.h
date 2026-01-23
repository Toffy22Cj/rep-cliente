#ifndef ACTIVIDADMODEL_H
#define ACTIVIDADMODEL_H

#include <QAbstractListModel>
#include "../models/StudentDTOs.h"

namespace Rep {

class ActividadModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        TituloRole,
        TipoRole,
        DescripcionRole,
        FechaEntregaRole,
        MateriaNombreRole,
        CursoNombreRole
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
            {CursoNombreRole, "cursoNombre"}
        };
    }

    void setActividades(const QList<ActividadDTO> &data) {
        beginResetModel();
        m_data = data;
        endResetModel();
    }
    void setData(const QList<ActividadDTO> &data) { setActividades(data); }

private:
    QList<ActividadDTO> m_data;
};

} // namespace Rep

#endif // ACTIVIDADMODEL_H
