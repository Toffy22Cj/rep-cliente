#ifndef MATERIAMODEL_H
#define MATERIAMODEL_H

#include <QAbstractListModel>
#include "../models/StudentDTOs.h"

namespace Rep {

class MateriaModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles { IdRole = Qt::UserRole + 1, NombreRole };
    explicit MateriaModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}

    int rowCount(const QModelIndex &parent = QModelIndex()) const override { return m_data.count(); }
    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_data.count()) return {};
        const auto &item = m_data[index.row()];
        if (role == IdRole) return item.id;
        if (role == NombreRole) return item.nombre;
        return {};
    }
    QHash<int, QByteArray> roleNames() const override {
        return { {IdRole, "id"}, {NombreRole, "nombre"} };
    }

    void setMaterias(const QList<MateriaDTO> &data) {
        beginResetModel();
        m_data = data;
        endResetModel();
    }
    void setData(const QList<MateriaDTO> &data) { setMaterias(data); } // Legacy

private:
    QList<MateriaDTO> m_data;
};

} // namespace Rep

#endif // MATERIAMODEL_H
