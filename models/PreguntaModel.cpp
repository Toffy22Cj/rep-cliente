#include "PreguntaModel.h"

namespace Rep {

PreguntaModel::PreguntaModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int PreguntaModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_questions.count();
}

QVariant PreguntaModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_questions.count())
        return QVariant();

    const PreguntaDTO &p = m_questions[index.row()];
    switch (role) {
    case IdRole: return p.id;
    case EnunciadoRole: return p.enunciado;
    case TipoRole: return p.tipo;
    case ArchivoUrlRole: return p.archivoUrl;
    case NombreArchivoRole: return p.nombreArchivo;
    case ArchivoDisponibleRole: return p.archivoDisponible;
    case OpcionesRole: {
        QVariantList ops;
        for (const auto &o : p.opciones) {
            QVariantMap map;
            map["id"] = o.id;
            map["texto"] = o.texto;
            map["esCorrecta"] = o.esCorrecta;
            map["archivoUrl"] = o.archivoUrl;
            map["nombreArchivo"] = o.nombreArchivo;
            map["archivoDisponible"] = o.archivoDisponible;
            ops.append(map);
        }
        return ops;
    }
    case RespuestaAbiertaRole: return p.respuestaAbierta;
    case OpcionSeleccionadaIdRole: return p.opcionSeleccionadaId;
    }
    return QVariant();
}

bool PreguntaModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid() || index.row() >= m_questions.count())
        return false;

    PreguntaDTO &p = m_questions[index.row()];
    if (role == RespuestaAbiertaRole) {
        p.respuestaAbierta = value.toString();
        emit dataChanged(index, index, {RespuestaAbiertaRole});
        return true;
    } else if (role == OpcionSeleccionadaIdRole) {
        p.opcionSeleccionadaId = value.toLongLong();
        emit dataChanged(index, index, {OpcionSeleccionadaIdRole});
        return true;
    }
    return false;
}

QHash<int, QByteArray> PreguntaModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[EnunciadoRole] = "enunciado";
    roles[TipoRole] = "tipo";
    roles[ArchivoUrlRole] = "archivoUrl";
    roles[NombreArchivoRole] = "nombreArchivo";
    roles[ArchivoDisponibleRole] = "archivoDisponible";
    roles[OpcionesRole] = "opciones";
    roles[RespuestaAbiertaRole] = "respuestaAbierta";
    roles[OpcionSeleccionadaIdRole] = "opcionSeleccionadaId";
    return roles;
}

void PreguntaModel::setQuestions(const QList<PreguntaDTO> &questions)
{
    beginResetModel();
    m_questions = questions;
    endResetModel();
}

void PreguntaModel::selectOpcion(int index, long long opcionId)
{
    if (index >= 0 && index < m_questions.count()) {
        m_questions[index].opcionSeleccionadaId = opcionId;
        emit dataChanged(this->index(index), this->index(index), {OpcionSeleccionadaIdRole});
    }
}

void PreguntaModel::setRespuestaAbierta(int index, const QString &respuesta)
{
    if (index >= 0 && index < m_questions.count()) {
        m_questions[index].respuestaAbierta = respuesta;
        emit dataChanged(this->index(index), this->index(index), {RespuestaAbiertaRole});
    }
}

} // namespace Rep
