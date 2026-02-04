#ifndef ADMINSERVICE_H
#define ADMINSERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include "../models/AdminDTOs.h"

namespace Rep {

class AdminService : public QObject
{
    Q_OBJECT
public:
    explicit AdminService(QObject *parent = nullptr);

    // Users
    void fetchUsuarios(const QString &token);
    void updateUsuario(const UsuarioDTO &usuario, const QString &token);
    void deleteUsuario(long long id, const QString &token);
    void toggleUsuarioEstado(long long id, bool activo, const QString &token);

    // Cursos
    void fetchCursos(const QString &token);
    void createCurso(const CursoAdminDTO &curso, const QString &token);
    void updateCurso(const CursoAdminDTO &curso, const QString &token);
    void deleteCurso(long long id, const QString &token);

    // Materias
    void fetchMaterias(const QString &token);
    void createMateria(const MateriaAdminDTO &materia, const QString &token);
    void updateMateria(const MateriaAdminDTO &materia, const QString &token);
    void deleteMateria(long long id, const QString &token);

    // Asignaciones
    void fetchAsignaciones(const QString &token);
    void createAsignacion(long long profesorId, long long materiaId, long long cursoId, const QString &token);
    void deleteAsignacion(long long id, const QString &token);

signals:
    void usuariosFetched(const QList<UsuarioDTO> &usuarios);
    void cursosFetched(const QList<CursoAdminDTO> &cursos);
    void materiasFetched(const QList<MateriaAdminDTO> &materias);
    void asignacionesFetched(const QList<AsignacionDTO> &asignaciones);
    
    void operationSuccess(const QString &message);
    void errorOccurred(const QString &error);

private:
    QNetworkAccessManager *m_networkManager;
    QNetworkRequest createRequest(const QUrl &url, const QString &token);
};

} // namespace Rep

#endif // ADMINSERVICE_H
