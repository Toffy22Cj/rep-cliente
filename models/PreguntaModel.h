#ifndef PREGUNTAMODEL_H
#define PREGUNTAMODEL_H

#include <QAbstractListModel>
#include "StudentDTOs.h"

namespace Rep {

class PreguntaModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum PreguntaRoles {
        IdRole = Qt::UserRole + 1,
        EnunciadoRole,
        TipoRole,
        ArchivoUrlRole,
        NombreArchivoRole,
        ArchivoDisponibleRole,
        OpcionesRole,
        RespuestaAbiertaRole,
        OpcionSeleccionadaIdRole
    };

    explicit PreguntaModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;

    void setQuestions(const QList<PreguntaDTO> &questions);
    
    const QList<PreguntaDTO>& questions() const { return m_questions; }

    Q_INVOKABLE void selectOpcion(int index, long long opcionId);
    Q_INVOKABLE void setRespuestaAbierta(int index, const QString &respuesta);

private:
    QList<PreguntaDTO> m_questions;
};

} // namespace Rep

#endif // PREGUNTAMODEL_H
