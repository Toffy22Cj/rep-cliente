#ifndef ADMINVIEWMODEL_H
#define ADMINVIEWMODEL_H

#include <QObject>
#include <QAbstractListModel>
#include "../api/AdminService.h"
#include "../models/AdminDTOs.h"

namespace Rep {

// --- Models ---

class UsuarioModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { IdRole = Qt::UserRole + 1, NombreRole, CorreoRole, RolRole, ActivoRole };
    explicit UsuarioModel(QObject *parent = nullptr);
    void updateData(const QList<UsuarioDTO> &data);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QVariantMap get(int row) const;
private:
    QList<UsuarioDTO> m_data;
};

class CursoAdminModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { IdRole = Qt::UserRole + 1, GradoRole, GrupoRole, DisplayNameRole };
    explicit CursoAdminModel(QObject *parent = nullptr);
    void updateData(const QList<CursoAdminDTO> &data);
    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QVariantMap get(int row) const;
private:
    QList<CursoAdminDTO> m_data;
};

class MateriaAdminModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { IdRole = Qt::UserRole + 1, NombreRole };
    explicit MateriaAdminModel(QObject *parent = nullptr);
    void updateData(const QList<MateriaAdminDTO> &data);
    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE QVariantMap get(int row) const;
private:
    QList<MateriaAdminDTO> m_data;
};

// --- ViewModel ---

class AdminViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(UsuarioModel* usuarioModel READ usuarioModel CONSTANT)
    Q_PROPERTY(CursoAdminModel* cursoModel READ cursoModel CONSTANT)
    Q_PROPERTY(MateriaAdminModel* materiaModel READ materiaModel CONSTANT)

public:
    explicit AdminViewModel(QObject *parent = nullptr);

    UsuarioModel* usuarioModel() const;
    CursoAdminModel* cursoModel() const;
    MateriaAdminModel* materiaModel() const;

    // Loaders
    Q_INVOKABLE void loadUsuarios();
    Q_INVOKABLE void loadCursos();
    Q_INVOKABLE void loadMaterias();

    // Actions
    Q_INVOKABLE void saveUsuario(long long id, const QString &nombre, const QString &correo, const QString &identificacion, const QString &rol, const QString &password, bool activo);
    Q_INVOKABLE void deleteUsuario(long long id);
    Q_INVOKABLE void toggleUsuarioEstado(long long id, bool activo);

    Q_INVOKABLE void createCurso(int grado, const QString &grupo);
    Q_INVOKABLE void updateCurso(long long id, int grado, const QString &grupo);
    Q_INVOKABLE void deleteCurso(long long id);

    Q_INVOKABLE void createMateria(const QString &nombre);
    Q_INVOKABLE void deleteMateria(long long id);

signals:
    void operationSuccess(const QString &msg);
    void errorOccurred(const QString &err);

private slots:
    void onUsuariosFetched(const QList<UsuarioDTO> &data);
    void onCursosFetched(const QList<CursoAdminDTO> &data);
    void onMateriasFetched(const QList<MateriaAdminDTO> &data);

private:
    AdminService *m_service;
    UsuarioModel *m_usuarioModel;
    CursoAdminModel *m_cursoModel;
    MateriaAdminModel *m_materiaModel;
};

} // namespace Rep

#endif // ADMINVIEWMODEL_H
