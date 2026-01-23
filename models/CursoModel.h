#ifndef CURSOMODEL_H
#define CURSOMODEL_H

#include <QAbstractListModel>
#include "ProfesorDTOs.h"

namespace Rep {

class CursoModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles { IdRole = Qt::UserRole + 1, NombreRole, GradoRole, GrupoRole };
    explicit CursoModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}

    int rowCount(const QModelIndex &parent = QModelIndex()) const override { return m_data.count(); }
    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_data.count()) return {};
        const auto &item = m_data[index.row()];
        if (role == IdRole) return item.id;
        if (role == NombreRole) {
            if (!item.nombre.isEmpty()) return item.nombre;
            return QString("%1 - %2").arg(item.grado).arg(item.grupo);
        }
        if (role == GradoRole) return item.grado;
        if (role == GrupoRole) return item.grupo;
        return {};
    }
    QHash<int, QByteArray> roleNames() const override {
        return { {IdRole, "id"}, {NombreRole, "nombre"}, {GradoRole, "grado"}, {GrupoRole, "grupo"} };
    }
    Q_INVOKABLE QVariantMap get(int row) const {
        if (row < 0 || row >= m_data.count()) return {};
        const auto &item = m_data[row];
        QString displayName = item.nombre.isEmpty() ? QString("%1 - %2").arg(item.grado).arg(item.grupo) : item.nombre;
        return { {"id", item.id}, {"nombre", displayName}, {"grado", item.grado}, {"grupo", item.grupo} };
    }

    void setCursos(const QList<CursoDTO> &data) {
        beginResetModel();
        m_data = data;
        endResetModel();
    }

private:
    QList<CursoDTO> m_data;
};

} // namespace Rep

#endif // CURSOMODEL_H
